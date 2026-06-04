require "test_helper"

class ProcessPhotoJobTest < ActiveSupport::TestCase
  test "classifies and eagerly generates WebP variants" do
    photo = build_photo_with_image # classification_override → :approved

    ProcessPhotoJob.perform_now(photo)

    assert photo.reload.approved?
    assert_equal Photo::PHOTO_VARIANTS.size,
                 ActiveStorage::VariantRecord.where(blob_id: photo.image.blob.id).count
  end

  test "falls back to manual review when the sidecar stays unavailable" do
    photo = build_photo_with_image
    NsfwDetector.classification_override = ->(*) { raise NsfwDetector::Unavailable }
    job = ProcessPhotoJob.new
    job.define_singleton_method(:executions) { 5 } # retries exhausted

    job.perform(photo)

    assert photo.reload.review?
  end

  test "no-op when image is missing" do
    photo = User.create!(email: "np@example.com", password: "secret123").photos.create!(position: 1)
    assert_nothing_raised { ProcessPhotoJob.perform_now(photo) }
  end

  private

  def build_photo_with_image
    user = User.create!(email: "pj@example.com", password: "secret123")
    photo = user.photos.create!(position: 1)
    photo.image.attach(io: File.open(file_fixture("sample.png")), filename: "sample.png", content_type: "image/png")
    photo
  end
end
