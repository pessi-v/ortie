# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE), not null
#  donor               :boolean          default(FALSE), not null
#  email               :citext           not null
#  last_active_at      :datetime
#  latitude            :decimal(10, 6)
#  location_label      :string
#  longitude           :decimal(10, 6)
#  message_preference  :integer          default("no_preference"), not null
#  password_digest     :string           not null
#  pending_likes_count :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_earth_location  (ll_to_earth((latitude)::double precision, (longitude)::double precision)) WHERE (active AND (latitude IS NOT NULL) AND (longitude IS NOT NULL)) USING gist
#  index_users_on_email           (email) UNIQUE
#  index_users_on_last_active_at  (last_active_at)
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :message_preference, {
    no_preference:          0,
    prefers_to_write_first: 1,
    prefers_intro:          2
  }, default: :no_preference

  has_one :profile, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_many :photos, dependent: :destroy

  # Directed like/pass edges.
  has_many :given_likes, class_name: "Like", foreign_key: :liker_id, dependent: :destroy, inverse_of: :liker
  has_many :received_likes, class_name: "Like", foreign_key: :liked_id, dependent: :destroy, inverse_of: :liked

  # Matches from either side.
  has_many :initiated_matches, class_name: "Match", foreign_key: :initiator_id, dependent: :destroy, inverse_of: :initiator
  has_many :received_matches, class_name: "Match", foreign_key: :receiver_id, dependent: :destroy, inverse_of: :receiver

  # Messaging.
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy, inverse_of: :sender

  # Reports.
  has_many :reports_made, class_name: "Report", foreign_key: :reporter_id, dependent: :destroy, inverse_of: :reporter
  has_many :reports_received, class_name: "Report", foreign_key: :reported_id, dependent: :destroy, inverse_of: :reported

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(active: true) }
  scope :with_approved_photo, -> { where(id: Photo.approved.select(:user_id)) }

  def unread_messages_count
    conversation_participants.sum(:unread_count)
  end

  def primary_photo
    photos.approved.order(:position).first
  end
end
