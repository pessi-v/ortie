require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "me@example.com", password: "secret123",
                         latitude: 52.5, longitude: 13.4, location_label: "Berlin")
    @user.create_profile!(display_name: "Me", birthdate: 30.years.ago.to_date, gender: :woman)
    @user.create_user_preference!(age_min: 25, age_max: 40, max_distance_km: 50,
                                  sought_genders: [Profile.genders[:man]])
    sign_in_as(@user)
  end

  test "show renders all sections" do
    get settings_path
    assert_response :success
    assert_select "section#profile"
    assert_select "section#preferences"
    assert_select "section#location"
    assert_select "section#account"
  end

  test "update_profile changes profile fields and message preference" do
    patch settings_profile_path, params: {
      profile: { display_name: "Renamed", bio: "hi", gender: "woman", self_described_gender: "" },
      user: { message_preference: "prefers_intro" }
    }
    assert_redirected_to settings_path(anchor: "profile")
    assert_equal "Renamed", @user.profile.reload.display_name
    assert_equal "prefers_intro", @user.reload.message_preference
  end

  test "update_profile with blank display_name is rejected" do
    patch settings_profile_path, params: {
      profile: { display_name: "", gender: "woman" }, user: { message_preference: "no_preference" }
    }
    assert_response :unprocessable_entity
    assert_equal "Me", @user.profile.reload.display_name
  end

  test "update_preferences changes range and sought genders" do
    patch settings_preferences_path, params: {
      user_preference: { age_min: "30", age_max: "45", max_distance_km: "20",
                         sought_genders: ["", Profile.genders[:woman].to_s] }
    }
    assert_redirected_to settings_path(anchor: "preferences")
    pref = @user.user_preference.reload
    assert_equal 30, pref.age_min
    assert_equal [Profile.genders[:woman]], pref.sought_genders
  end

  test "update_preferences with inverted age range is rejected" do
    patch settings_preferences_path, params: {
      user_preference: { age_min: "50", age_max: "20", max_distance_km: "20", sought_genders: [""] }
    }
    assert_response :unprocessable_entity
    assert_equal 25, @user.user_preference.reload.age_min
  end

  test "update_location updates coordinates" do
    patch settings_location_path, params: { user: { latitude: "48.8", longitude: "2.3", location_label: "Paris" } }
    assert_redirected_to settings_path(anchor: "location")
    @user.reload
    assert_equal "Paris", @user.location_label
    assert_in_delta 48.8, @user.latitude.to_f, 0.001
  end

  test "update_account rejects a wrong current password" do
    patch settings_account_path, params: { account: { email: "new@example.com", current_password: "wrong" } }
    assert_response :unprocessable_entity
    assert_equal "me@example.com", @user.reload.email
  end

  test "update_account changes email with correct current password" do
    patch settings_account_path, params: { account: { email: "new@example.com", current_password: "secret123" } }
    assert_redirected_to settings_path(anchor: "account")
    assert_equal "new@example.com", @user.reload.email
  end

  test "update_account changes password and the new one authenticates" do
    patch settings_account_path, params: {
      account: { email: @user.email, password: "newsecret1", password_confirmation: "newsecret1", current_password: "secret123" }
    }
    assert_redirected_to settings_path(anchor: "account")
    assert User.authenticate_by(email: "me@example.com", password: "newsecret1")
  end

  test "deactivate and reactivate toggle the active flag and discovery visibility" do
    patch settings_active_path, params: { active: "false" }
    assert_not @user.reload.active?
    assert_not_includes User.active, @user

    patch settings_active_path, params: { active: "true" }
    assert @user.reload.active?
  end
end
