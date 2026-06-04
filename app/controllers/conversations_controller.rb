class ConversationsController < ApplicationController
  def show
    @conversation = current_conversations.find(params[:id])
    @messages = @conversation.messages.includes(sender: :profile).order(:created_at)
    @other = @conversation.match.other_user(Current.user)
    @message = Message.new

    mark_read(@conversation)
  end

  private

  # Only conversations the current user participates in, and only for matches
  # that are still confirmed (an unmatched conversation isn't reachable).
  def current_conversations
    Current.user.conversations.joins(:match).merge(Match.confirmed)
  end

  def mark_read(conversation)
    participant = conversation.conversation_participants.find_by(user: Current.user)
    participant&.update!(unread_count: 0, last_read_at: Time.current)
  end
end
