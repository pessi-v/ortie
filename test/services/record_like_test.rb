require "test_helper"

class RecordLikeTest < ActiveSupport::TestCase
  setup do
    @a = make_user("aaa")
    @b = make_user("bbb")
  end

  test "mutual like creates a confirmed match with a conversation and two participants" do
    RecordLike.new(actor: @b, target: @a, kind: :like).call # b likes a first
    result = RecordLike.new(actor: @a, target: @b, kind: :like).call # a likes back

    assert result.matched
    match = Match.between(@a, @b).first
    assert_predicate match, :confirmed?
    assert_equal @b.id, match.initiator_id, "earlier liker is the initiator"
    assert_not_nil match.conversation
    assert_equal 2, match.conversation.conversation_participants.count
  end

  test "match creation is idempotent" do
    RecordLike.new(actor: @b, target: @a, kind: :like).call
    RecordLike.new(actor: @a, target: @b, kind: :like).call
    RecordLike.new(actor: @a, target: @b, kind: :like).call # repeat

    assert_equal 1, Match.between(@a, @b).count
    assert_equal 1, Conversation.joins(:match).merge(Match.between(@a, @b)).count
  end

  test "pending_likes_count tracks incoming likes" do
    assert_equal 0, @a.reload.pending_likes_count

    RecordLike.new(actor: @b, target: @a, kind: :like).call
    assert_equal 1, @a.reload.pending_likes_count, "a was liked → +1"

    RecordLike.new(actor: @a, target: @b, kind: :like).call # a acts on b
    assert_equal 0, @a.reload.pending_likes_count, "a consumed the pending like"
    assert_equal 0, @b.reload.pending_likes_count, "mutual match never counted as pending for b"
  end

  test "passing after a match declines it (unmatch)" do
    RecordLike.new(actor: @b, target: @a, kind: :like).call
    RecordLike.new(actor: @a, target: @b, kind: :like).call
    assert_predicate Match.between(@a, @b).first, :confirmed?

    RecordLike.new(actor: @a, target: @b, kind: :pass).call
    assert_predicate Match.between(@a, @b).first, :declined?
  end

  test "a like row is reused, not duplicated, when changed" do
    RecordLike.new(actor: @a, target: @b, kind: :pass).call
    RecordLike.new(actor: @a, target: @b, kind: :like).call

    assert_equal 1, Like.where(liker_id: @a.id, liked_id: @b.id).count
    assert_predicate Like.find_by(liker_id: @a.id, liked_id: @b.id), :like?
  end

  private

  def make_user(name)
    user = User.create!(email: "#{name}@example.com", password: "secret123")
    user.create_profile!(display_name: name, birthdate: 30.years.ago.to_date, gender: :man)
    user
  end
end
