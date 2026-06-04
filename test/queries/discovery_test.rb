require "test_helper"

class DiscoveryTest < ActiveSupport::TestCase
  # Build a small social graph around @me and assert each section's membership.
  setup do
    @me = make_user("me", gender: :woman, age: 30)
    @me.create_user_preference!(age_min: 25, age_max: 40, max_distance_km: 100,
                                sought_genders: [Profile.genders[:man]])

    @alice = make_user("alice", gender: :man, age: 30) # no interaction → New
    @bob   = make_user("bob",   gender: :man, age: 30) # I liked → Liked
    @carol = make_user("carol", gender: :man, age: 30) # I passed → Passed
    @dave  = make_user("dave",  gender: :man, age: 30) # liked me → Likes You
    @eve   = make_user("eve",   gender: :man, age: 30) # mutual → Matches
    @frank = make_user("frank", gender: :man, age: 30) # passed me → hidden everywhere
    @hank  = make_user("hank",  gender: :man, age: 30) # I liked, then passed me → not in Liked
    @grace = make_user("grace", gender: :woman, age: 30) # wrong gender → not New
    @old   = make_user("old",   gender: :man, age: 60)   # out of age range → not New
    @far   = make_user("far",   gender: :man, age: 30, lat: -33.86, lng: 151.20) # too far → not New

    Like.create!(liker: @me,   liked: @bob,   kind: :like)
    Like.create!(liker: @me,   liked: @carol, kind: :pass)
    Like.create!(liker: @dave, liked: @me,    kind: :like)
    Like.create!(liker: @me,   liked: @eve,   kind: :like)
    Like.create!(liker: @eve,  liked: @me,    kind: :like)
    Match.create!(initiator: @eve, receiver: @me, status: :confirmed, confirmed_at: Time.current)
    Like.create!(liker: @frank, liked: @me,   kind: :pass)
    Like.create!(liker: @me,    liked: @hank, kind: :like)
    Like.create!(liker: @hank,  liked: @me,   kind: :pass)

    @discovery = Discovery.new(@me)
  end

  test "new_profiles shows only people with no interaction, within preferences" do
    ids = @discovery.new_profiles.map(&:id)
    assert_includes ids, @alice.id
    [@bob, @carol, @dave, @eve, @frank, @hank, @grace, @old, @far, @me].each do |u|
      assert_not_includes ids, u.id, "#{u.profile.display_name} should not be in New profiles"
    end
  end

  test "new_profiles excludes people without an approved photo" do
    photoless = make_user("photoless", gender: :man, age: 30, photo: false)
    assert_not_includes @discovery.new_profiles.map(&:id), photoless.id
  end

  test "liked shows people I liked, minus anyone who has since passed me" do
    ids = @discovery.liked.map(&:id)
    assert_includes ids, @bob.id
    assert_not_includes ids, @hank.id, "hank passed me, so should drop out of Liked"
    assert_not_includes ids, @carol.id, "carol was passed, not liked"
  end

  test "passed shows people I passed" do
    ids = @discovery.passed.map(&:id)
    assert_equal [@carol.id], ids
  end

  test "matches shows confirmed mutual likes" do
    matches = @discovery.matches.to_a
    assert_equal 1, matches.size
    assert_equal @eve.id, matches.first.other_user(@me).id
  end

  test "likes_you shows people who liked me that I haven't acted on" do
    ids = @discovery.likes_you.map(&:id)
    assert_includes ids, @dave.id
    assert_not_includes ids, @eve.id, "eve is a match (I liked back), not a pending like"
    assert_not_includes ids, @frank.id, "frank passed me"
  end

  private

  def make_user(name, gender:, age:, lat: 52.50, lng: 13.40, active: true, photo: true)
    user = User.create!(email: "#{name}@example.com", password: "secret123",
                        latitude: lat, longitude: lng, location_label: "Berlin",
                        active: active, last_active_at: Time.current)
    user.create_profile!(display_name: name.capitalize, birthdate: age.years.ago.to_date, gender: gender)
    user.photos.create!(position: 1, moderation_status: :approved) if photo
    user
  end
end
