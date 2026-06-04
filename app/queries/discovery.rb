# Builds the five discovery sections for a given user. Each method returns an
# ActiveRecord::Relation so callers can paginate/preload as needed.
#
# Section definitions (see dating_app_architecture.md):
#   new_profiles — active users with NO like/pass interaction in either direction
#   liked        — people I liked, minus anyone who has since passed me
#   passed       — people I passed (reviewable / un-passable)
#   matches      — confirmed mutual likes
#   likes_you    — people who liked me that I haven't acted on
class Discovery
  DEFAULT_DISTANCE_KM = 50

  def initialize(user)
    @user = user
  end

  # No interaction in either direction, filtered by preferences, ordered by
  # proximity (closest first) when we know the viewer's location.
  def new_profiles
    rel = User.active
              .with_approved_photo
              .where.not(id: @user.id)
              .where.not(id: my_passed_ids)
              .where.not(id: my_liked_ids)
              .where.not(id: passed_me_ids)
              .where.not(id: liked_me_ids)
              .joins(:profile)
    rel = apply_preferences(rel)
    apply_distance(rel)
  end

  # People I liked, dropping anyone who has since passed me.
  def liked
    User.joins(:profile)
        .joins(like_join("likes.liked_id = users.id", "likes.liker_id = ?", :like))
        .where.not(id: passed_me_ids)
        .order("likes.created_at DESC")
  end

  # People I passed — reviewable so they can be un-passed.
  def passed
    User.joins(:profile)
        .joins(like_join("likes.liked_id = users.id", "likes.liker_id = ?", :pass))
        .order("likes.created_at DESC")
  end

  # Confirmed mutual likes, ordered as an inbox (most recent activity first).
  # Returns Match records; views use Match#other_user and match.conversation.
  def matches
    Match.confirmed
         .for_user(@user)
         .includes(initiator: :profile, receiver: :profile,
                   conversation: [:conversation_participants, { messages: :sender }])
         .left_joins(:conversation)
         .order(Arel.sql("conversations.last_message_at DESC NULLS LAST, matches.confirmed_at DESC"))
  end

  # People who liked me that I haven't acted on. Exposes each like's intro_note
  # and liked_at as selected columns.
  def likes_you
    User.joins(:profile)
        .joins(like_join("likes.liker_id = users.id", "likes.liked_id = ?", :like))
        .where.not(id: my_liked_ids)
        .where.not(id: my_passed_ids)
        .select("users.*, likes.intro_note AS intro_note, likes.created_at AS liked_at")
        .order("likes.created_at DESC")
  end

  private

  def my_passed_ids
    Like.where(liker_id: @user.id, kind: :pass).select(:liked_id)
  end

  def my_liked_ids
    Like.where(liker_id: @user.id, kind: :like).select(:liked_id)
  end

  def passed_me_ids
    Like.where(liked_id: @user.id, kind: :pass).select(:liker_id)
  end

  def liked_me_ids
    Like.where(liked_id: @user.id, kind: :like).select(:liker_id)
  end

  # An INNER JOIN onto the current user's directed like edge, e.g. for "liked":
  #   like_join("likes.liked_id = users.id", "likes.liker_id = ?", :like)
  def like_join(match_clause, owner_clause, kind)
    ActiveRecord::Base.sanitize_sql_array([
      "INNER JOIN likes ON #{match_clause} AND #{owner_clause} AND likes.kind = ?",
      @user.id, Like.kinds[kind]
    ])
  end

  def apply_preferences(rel)
    pref = @user.user_preference
    return rel unless pref

    rel = rel.where(profiles: { gender: pref.sought_genders }) if pref.sought_genders.present?
    rel = rel.where("profiles.birthdate <= (CURRENT_DATE - make_interval(years => ?))", pref.age_min)
    rel.where("profiles.birthdate > (CURRENT_DATE - make_interval(years => ?))", pref.age_max + 1)
  end

  # Filter and order by great-circle distance from the viewer. Without a
  # location we can't compute distance, so fall back to most-recently-active.
  def apply_distance(rel)
    return rel.order(last_active_at: :desc) unless @user.latitude && @user.longitude

    km = @user.user_preference&.max_distance_km || DEFAULT_DISTANCE_KM
    origin = "ll_to_earth(#{@user.latitude.to_f}, #{@user.longitude.to_f})"
    distance = "earth_distance(#{origin}, ll_to_earth(users.latitude, users.longitude))"

    rel.where("users.latitude IS NOT NULL AND users.longitude IS NOT NULL")
       .where("#{distance} <= ?", km * 1000)
       .select("users.*, #{distance} AS distance")
       .order(Arel.sql("#{distance} ASC"))
  end
end
