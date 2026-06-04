require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign-up works when the nsfw sidecar is up" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_redirected_to onboarding_path
  end

  test "sign-up is blocked when the nsfw sidecar is down" do
    NsfwDetector.service_available_override = false

    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_response :service_unavailable
    assert_match(/paused/i, @response.body)
  end

  test "new page shows the paused banner when down" do
    NsfwDetector.service_available_override = false
    get new_registration_path
    assert_response :service_unavailable
    assert_match(/paused/i, @response.body)
  end
end
