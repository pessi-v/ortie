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
