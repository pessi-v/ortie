# == Schema Information
#
# Table name: likes
#
#  id         :bigint           not null, primary key
#  intro_note :text
#  kind       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  liked_id   :bigint           not null
#  liker_id   :bigint           not null
#
# Indexes
#
#  index_likes_on_liked_id_and_kind      (liked_id,kind)
#  index_likes_on_liker_id_and_kind      (liker_id,kind)
#  index_likes_on_liker_id_and_liked_id  (liker_id,liked_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (liked_id => users.id) ON DELETE => cascade
#  fk_rails_...  (liker_id => users.id) ON DELETE => cascade
#
class Like < ApplicationRecord
  belongs_to :liker, class_name: "User", inverse_of: :given_likes
  belongs_to :liked, class_name: "User", inverse_of: :received_likes

  enum :kind, { like: 0, pass: 1 }

  validates :liker_id, uniqueness: { scope: :liked_id }
  validate :not_self

  private

  def not_self
    errors.add(:liked_id, "can't be yourself") if liker_id.present? && liker_id == liked_id
  end
end
