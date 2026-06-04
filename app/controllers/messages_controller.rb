class MessagesController < ApplicationController
  def create
    @conversation = current_conversations.find(params[:conversation_id])
    @message = @conversation.messages.new(message_params.merge(sender: Current.user))

    if @message.save
      deliver(@message)
      respond_to do |format|
        format.turbo_stream # resets the compose form; the bubble arrives via broadcast
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @conversation, alert: "Message can't be blank." }
      end
    end
  end

  private

  def current_conversations
    Current.user.conversations.joins(:match).merge(Match.confirmed)
  end

  def message_params
    params.expect(message: %i[body])
  end

  # Bump conversation activity, the recipient's unread counter, and push a live
  # nav-badge update to the recipient. (The message bubble itself broadcasts
  # from the Message model.)
  def deliver(message)
    conversation = message.conversation
    conversation.update!(last_message_at: message.created_at)

    recipient_participant = conversation.conversation_participants.where.not(user_id: Current.user.id).first
    recipient_participant.increment!(:unread_count)

    recipient = recipient_participant.user
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{recipient.id}_nav",
      target: "matches-unread-badge",
      partial: "shared/nav_unread_badge",
      locals: { count: recipient.unread_messages_count }
    )
  end
end
