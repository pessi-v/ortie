require "test_helper"

class DiscoveryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @me = make_user("me")
    @them = make_user("them")
    @them.photos.create!(position: 1, moderation_status: :approved)
    sign_in_as(@me)
  end

  test "new profiles renders as a one-at-a-time swipe carousel" do
    get root_path
    assert_response :success
    assert_select "[data-controller=carousel]"
    assert_select ".carousel-slide#profile_#{@them.id}", 1
    assert_select "[data-action='carousel#next']"
  end

  test "explicit like/pass actions remain on the profile (swipe is navigation only)" do
    get root_path
    assert_select "form[action=?]", like_profile_path(@them)
    assert_select "form[action=?]", pass_profile_path(@them)
  end

  private

  def make_user(name)
    user = User.create!(email: "#{name}@example.com", password: "secret123",
                        latitude: 52.5, longitude: 13.4, location_label: "Berlin")
    user.create_profile!(display_name: name, birthdate: 30.years.ago.to_date, gender: :man)
    user.create_user_preference!(sought_genders: Profile.genders.values)
    user
  end
end
