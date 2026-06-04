class Match < ApplicationRecord
  belongs_to :initiator, class_name: "User", inverse_of: :initiated_matches
  belongs_to :receiver, class_name: "User", inverse_of: :received_matches

  has_one :conversation, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, declined: 2 }, default: :confirmed

  validate :not_self

  scope :for_user, ->(user) { where(initiator: user).or(where(receiver: user)) }
  scope :between, ->(a, b) { where(initiator: a, receiver: b).or(where(initiator: b, receiver: a)) }

  # The other party from the perspective of the given user.
  def other_user(user)
    initiator_id == user.id ? receiver : initiator
  end

  private

  def not_self
    errors.add(:receiver_id, "can't be yourself") if initiator_id.present? && initiator_id == receiver_id
  end
end
