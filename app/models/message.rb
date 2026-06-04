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
