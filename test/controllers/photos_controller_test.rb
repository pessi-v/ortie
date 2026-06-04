require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = make_user("owner")
    sign_in_as(@user)
  end

  test "index renders the gallery with an attached photo" do
    photo = @user.photos.create!(position: 1, moderation_status: :approved)
    photo.image.attach(io: File.open(file_fixture("sample.png")), filename: "sample.png", content_type: "image/png")

    get photos_path
    assert_response :success
    assert_select "#photo_#{photo.id}"
  end

  test "upload form scopes the file field under photo[image]" do
    get photos_path
    assert_response :success
    assert_select "input[type=file][name='photo[image]']"
  end

  test "upload attaches a photo at the next position and enqueues processing" do
    assert_enqueued_with(job: ProcessPhotoJob) do
      assert_difference -> { @user.photos.count }, 1 do
        post photos_path, params: { photo: { image: upload } }
      end
    end
    assert_redirected_to photos_path
    assert_equal 1, @user.photos.first.position
  end

  test "upload beyond the max is rejected" do
    6.times { |i| @user.photos.create!(position: i + 1) }
    assert_no_difference -> { @user.photos.count } do
      post photos_path, params: { photo: { image: upload } }
    end
    assert_redirected_to photos_path
    assert_match(/maximum/i, flash[:alert])
  end

  test "destroy removes the photo and reindexes positions" do
    p1 = @user.photos.create!(position: 1)
    p2 = @user.photos.create!(position: 2)
    p3 = @user.photos.create!(position: 3)

    delete photo_path(p2)

    assert_nil Photo.find_by(id: p2.id)
    assert_equal 1, p1.reload.position
    assert_equal 2, p3.reload.position
  end

  test "make_primary moves a photo to position 1 and shifts the rest" do
    p1 = @user.photos.create!(position: 1)
    p2 = @user.photos.create!(position: 2)
    p3 = @user.photos.create!(position: 3)

    patch make_primary_photo_path(p3)

    assert_equal 1, p3.reload.position
    assert_equal 2, p1.reload.position
    assert_equal 3, p2.reload.position
  end

  test "cannot touch another user's photo" do
    other = make_user("other")
    others_photo = other.photos.create!(position: 1)
    delete photo_path(others_photo)
    assert_response :not_found
    assert Photo.exists?(others_photo.id)
  end

  test "upload is blocked when the nsfw sidecar is down" do
    NsfwDetector.service_available_override = false
    assert_no_difference -> { @user.photos.count } do
      post photos_path, params: { photo: { image: upload } }
    end
    assert_redirected_to photos_path
    assert_match(/paused/i, flash[:alert])
  end

  test "index shows the paused message and no upload field when down" do
    NsfwDetector.service_available_override = false
    get photos_path
    assert_response :success
    assert_select "input[type=file]", false
    assert_match(/paused/i, @response.body)
  end

  private

  def upload
    fixture_file_upload("sample.png", "image/png")
  end

  def make_user(name)
    user = User.create!(email: "#{name}@example.com", password: "secret123")
    user.create_profile!(display_name: name, birthdate: 30.years.ago.to_date, gender: :man)
    user
  end
end
