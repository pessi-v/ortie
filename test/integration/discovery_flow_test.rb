require "test_helper"

class DiscoveryFlowTest < ActionDispatch::IntegrationTest
  test "sign up, onboard, browse, like into a match, pass, un-pass, flag" do
    # An existing person who will become a match.
    admirer = User.create!(email: "admirer@example.com", password: "secret123",
                           latitude: 52.50, longitude: 13.40, location_label: "Berlin",
                           last_active_at: Time.current)
    admirer.create_profile!(display_name: "Admirer", birthdate: 29.years.ago.to_date, gender: :woman)
    admirer.create_user_preference!(sought_genders: [Profile.genders[:woman]])
    admirer.photos.create!(position: 1, moderation_status: :approved)

    bystander = User.create!(email: "bystander@example.com", password: "secret123",
                             latitude: 52.51, longitude: 13.41, location_label: "Berlin",
                             last_active_at: Time.current)
    bystander.create_profile!(display_name: "Bystander", birthdate: 31.years.ago.to_date, gender: :woman)
    bystander.photos.create!(position: 1, moderation_status: :approved)

    # 1. Sign up
    post registration_path, params: { user: { email: "me@example.com", password: "secret123", password_confirmation: "secret123" } }
    assert_redirected_to onboarding_path
    me = User.find_by(email: "me@example.com")
    assert_not_nil me

    # Guard: discovery is blocked until onboarding is done
    get root_path
    assert_redirected_to onboarding_path

    # 2. Onboard
    admirer_likes_me = RecordLike.new(actor: admirer, target: me, kind: :like) # set up before we can match
    post onboarding_path, params: {
      profile: { display_name: "Me", birthdate: 30.years.ago.to_date.to_s, gender: "woman" },
      user_preference: { age_min: "25", age_max: "40", max_distance_km: "100", sought_genders: ["", Profile.genders[:woman].to_s] },
      user: { latitude: "52.50", longitude: "13.40", location_label: "Berlin", message_preference: "prefers_intro" }
    }
    assert_redirected_to root_path
    me.reload
    assert me.profile.present?, "profile created"
    assert_equal [Profile.genders[:woman]], me.user_preference.sought_genders
    assert_equal "prefers_intro", me.message_preference

    admirer_likes_me.call # admirer likes me → I should see them in Likes You

    # 3. New profiles shows the bystander, not the admirer (who liked me)
    get root_path
    assert_response :success
    assert_select "#profile_#{bystander.id}"
    assert_select "#profile_#{admirer.id}", false

    # 4. Likes You shows the admirer
    get likes_you_path
    assert_response :success
    assert_select "#profile_#{admirer.id}"

    # 5. Like the admirer back → match (turbo stream)
    post like_profile_path(admirer), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "match", @response.body
    assert Match.between(me, admirer).first&.confirmed?

    get matches_path
    match = Match.between(me, admirer).first
    assert_select "a[href=?]", conversation_path(match.conversation)

    # Messaging: send a message, recipient's unread reflects it
    post conversation_messages_path(match.conversation), params: { message: { body: "hey!" } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal 1, admirer.reload.unread_messages_count

    # 6. Pass the bystander → appears in Passed, gone from New
    post pass_profile_path(bystander)
    get passed_path
    assert_select "#profile_#{bystander.id}"
    get root_path
    assert_select "#profile_#{bystander.id}", false

    # 7. Un-pass → back in New
    post unpass_profile_path(bystander)
    get root_path
    assert_select "#profile_#{bystander.id}"

    # 8. Flag creates a report
    assert_difference -> { Report.count }, 1 do
      post flag_profile_path(bystander), params: { reason: "spam" }
    end
  end
end
