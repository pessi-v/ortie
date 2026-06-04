class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User", inverse_of: :reports_made
  belongs_to :reported, class_name: "User", inverse_of: :reports_received
  belongs_to :photo, optional: true

  enum :reason, {
    spam:                 0,
    harassment:           1,
    inappropriate_photos: 2,
    fake:                 3,
    other:                4
  }

  enum :status, {
    pending:   0,
    reviewed:  1,
    actioned:  2,
    dismissed: 3
  }, default: :pending

  validates :reason, presence: true
  validate :not_self

  private

  def not_self
    errors.add(:reported_id, "can't report yourself") if reporter_id.present? && reporter_id == reported_id
  end
end
