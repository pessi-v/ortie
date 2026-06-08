# Runs on every photo upload: classifies via the nsfwjs sidecar, sets the
# moderation status, then eagerly generates WebP variants (skipped for rejected
# photos, which are never served).
class ProcessPhotoJob < ApplicationJob
  queue_as :default

  # Uploads are gated on the sidecar being available, but it can drop between the
  # upload and this job. Ride out a brief outage; if it stays down, fall back to
  # manual review rather than losing the photo.
  retry_on NsfwDetector::Unavailable, wait: :polynomially_longer, attempts: 5

  discard_on ActiveJob::DeserializationError # photo deleted before processing

  def perform(photo)
    return unless photo.image.attached?

    status = classify(photo)
    photo.update!(moderation_status: status)

    unless photo.rejected?
      Photo::PHOTO_VARIANTS.each_key { |name| photo.image.variant(name).processed }
    end

    photo.broadcast_replace_to "photo_#{photo.id}",
      target: "photo_#{photo.id}_status",
      partial: "photos/photo_status",
      locals: { photo: photo }

    if photo.rejected?
      photo.broadcast_replace_to "photo_#{photo.id}",
        target: "photo_#{photo.id}_image",
        partial: "photos/photo_image",
        locals: { photo: photo }
    end
  end

  private

  def classify(photo)
    photo.image.blob.open { |file| NsfwDetector.classify(file.path) }
  rescue NsfwDetector::Unavailable
    raise if executions < 5 # let retry_on handle earlier attempts

    :review # retries exhausted — send to the manual queue
  end
end
