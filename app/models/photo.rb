class Photo < ApplicationRecord
  MAX_PER_USER = 6

  # Eagerly generated WebP variants (built by a background job on upload).
  PHOTO_VARIANTS = {
    thumb: { resize_to_fill: [120, 120],    format: :webp, saver: { quality: 80 } },
    card:  { resize_to_fill: [600, 750],     format: :webp, saver: { quality: 85 } },
    full:  { resize_to_limit: [1200, 1500],  format: :webp, saver: { quality: 88 } }
  }.freeze

  belongs_to :user

  has_one_attached :image do |attachable|
    PHOTO_VARIANTS.each { |name, opts| attachable.variant(name, **opts) }
  end

  enum :moderation_status, {
    pending:  0,
    approved: 1,
    review:   2,
    rejected: 3
  }, default: :pending

  validates :position, presence: true,
                       inclusion: { in: 1..MAX_PER_USER },
                       uniqueness: { scope: :user_id }
  validate :within_photo_limit, on: :create

  private

  def within_photo_limit
    return if user.blank?

    errors.add(:base, "can have at most #{MAX_PER_USER} photos") if user.photos.count >= MAX_PER_USER
  end
end
