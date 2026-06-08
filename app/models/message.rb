# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  body            :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  sender_id       :bigint           not null
#
# Indexes
#
#  index_messages_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_messages_on_sender_id                       (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (sender_id => users.id) ON DELETE => cascade
#
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages

  validates :body, presence: true

  # Append each new message to everyone subscribed to the conversation stream
  # (both participants, including the sender). Renders without a current user,
  # so messages/_message must not branch on Current.user.
  broadcasts_to ->(message) { message.conversation }, inserts_by: :append,
                target: "messages", partial: "messages/message"
end
