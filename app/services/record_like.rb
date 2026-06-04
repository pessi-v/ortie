# Records a like or pass from one user toward another and keeps everything that
# hangs off it consistent: the single directed edge, the "Likes You" counter
# cache, mutual-like → confirmed Match (+ Conversation), and pass-after-match
# unmatching. Idempotent — safe to call repeatedly.
class RecordLike
  Result = Data.define(:like, :matched)

  def initialize(actor:, target:, kind:, intro_note: nil)
    @actor = actor
    @target = target
    @kind = kind.to_sym
    @intro_note = intro_note
  end

  def call
    matched = false

    ActiveRecord::Base.transaction do
      consume_incoming_like
      like = upsert_like
      matched = @kind == :like ? create_match_if_mutual : (decline_match_if_any && false)
      @result = Result.new(like: like, matched: matched)
    end

    @result
  end

  private

  # Acting on someone who had liked me (they were pending in my Likes You)
  # removes them from that pending count — but only the first time I act.
  def consume_incoming_like
    return unless Like.exists?(liker_id: @target.id, liked_id: @actor.id, kind: :like)
    return if Like.exists?(liker_id: @actor.id, liked_id: @target.id) # already acted before
    return unless @actor.pending_likes_count.positive?

    @actor.decrement!(:pending_likes_count)
  end

  def upsert_like
    like = Like.find_or_initialize_by(liker_id: @actor.id, liked_id: @target.id)
    fresh_incoming = like.new_record? && @kind == :like
    like.kind = @kind
    like.intro_note = @intro_note if @intro_note.present?
    like.save!

    # A new like lands in the target's Likes You only if they haven't already
    # acted on me (otherwise it's an instant match or already-passed → hidden).
    if fresh_incoming && !Like.exists?(liker_id: @target.id, liked_id: @actor.id)
      @target.increment!(:pending_likes_count)
    end

    like
  end

  def create_match_if_mutual
    return false unless Like.exists?(liker_id: @target.id, liked_id: @actor.id, kind: :like)

    match = Match.between(@actor, @target).first
    if match
      match.update!(status: :confirmed, confirmed_at: match.confirmed_at || Time.current) unless match.confirmed?
    else
      # Initiator is the earlier liker — the target, whose like already existed.
      match = Match.create!(initiator: @target, receiver: @actor,
                            status: :confirmed, confirmed_at: Time.current)
    end
    ensure_conversation(match)
    true
  end

  def decline_match_if_any
    match = Match.between(@actor, @target).confirmed.first
    match&.update!(status: :declined)
    true
  end

  def ensure_conversation(match)
    conversation = Conversation.find_or_create_by!(match: match)
    [match.initiator_id, match.receiver_id].each do |user_id|
      ConversationParticipant.find_or_create_by!(conversation: conversation, user_id: user_id)
    end
    conversation
  end
end
