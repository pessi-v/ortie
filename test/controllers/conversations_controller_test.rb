require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @a, @b = matched_pair
    @conversation = Match.between(@a, @b).first.conversation
  end

  test "participant sees the thread and it marks their messages read" do
    # b has an unread message from a
    Message.create!(conversation: @conversation, sender: @a, body: "hi b")
    @conversation.conversation_participants.find_by(user: @b).update!(unread_count: 1)

    sign_in_as(@b)
    get conversation_path(@conversation)
    assert_response :success
    assert_select "#message_#{Message.last.id}"
    assert_equal 0, @conversation.conversation_participants.find_by(user: @b).reload.unread_count
  end

  test "non-participant gets 404" do
    sign_in_as(make_user("intruder"))
    get conversation_path(@conversation)
    assert_response :not_found
  end

  test "declined (unmatched) conversation is not reachable" do
    Match.between(@a, @b).first.update!(status: :declined)
    sign_in_as(@a)
    get conversation_path(@conversation)
    assert_response :not_found
  end

  private

  def matched_pair
    a = make_user("aaa")
    b = make_user("bbb")
    RecordLike.new(actor: a, target: b, kind: :like).call
    RecordLike.new(actor: b, target: a, kind: :like).call
    [a, b]
  end

  def make_user(name)
    user = User.create!(email: "#{name}@example.com", password: "secret123")
    user.create_profile!(display_name: name, birthdate: 30.years.ago.to_date, gender: :man)
    user
  end
end
