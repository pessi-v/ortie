require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @a, @b = matched_pair
    @conversation = Match.between(@a, @b).first.conversation
  end

  test "participant posts a message; recipient unread and activity update" do
    sign_in_as(@a)

    assert_difference -> { @conversation.messages.count }, 1 do
      post conversation_messages_path(@conversation), params: { message: { body: "hello" } }, headers: TURBO
    end
    assert_response :success

    recipient = @conversation.conversation_participants.find_by(user: @b)
    assert_equal 1, recipient.reload.unread_count
    assert_equal 1, @b.reload.unread_messages_count
    assert_not_nil @conversation.reload.last_message_at
  end

  test "blank message is rejected" do
    sign_in_as(@a)

    assert_no_difference -> { Message.count } do
      post conversation_messages_path(@conversation), params: { message: { body: "" } }, headers: TURBO
    end
    assert_response :unprocessable_entity
  end

  test "non-participant cannot post" do
    intruder = make_user("intruder")
    sign_in_as(intruder)

    assert_no_difference -> { Message.count } do
      post conversation_messages_path(@conversation), params: { message: { body: "hi" } }
    end
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
