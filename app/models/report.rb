# == Schema Information
#
# Table name: reports
#
#  id          :bigint           not null, primary key
#  note        :text
#  reason      :integer          not null
#  status      :integer          default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  photo_id    :bigint
#  reported_id :bigint           not null
#  reporter_id :bigint           not null
#
# Indexes
#
#  index_reports_on_photo_id     (photo_id)
#  index_reports_on_reported_id  (reported_id)
#  index_reports_on_reporter_id  (reporter_id)
#  index_reports_pending         (status) WHERE (status = 0)
#
# Foreign Keys
#
#  fk_rails_...  (photo_id => photos.id) ON DELETE => nullify
#  fk_rails_...  (reported_id => users.id) ON DELETE => cascade
#  fk_rails_...  (reporter_id => users.id) ON DELETE => cascade
#
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
