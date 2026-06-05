# Serves the Hotwire Native path configuration consumed by the mobile apps.
#
# This endpoint is the *remote* source of truth; each native app also ships an
# identical copy bundled in its binary as an offline fallback (for Android:
# android/app/src/main/assets/json/configuration.json). Keep the two in sync.
#
# `rules` map URL patterns to native presentation. The default rule renders every
# location in the standard web fragment with pull-to-refresh. Add more specific
# rules (e.g. `context: "modal"`) above it as the native experience grows.
class ConfigurationsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_onboarding

  PATH_CONFIGURATION = {
    settings: {},
    rules: [
      {
        patterns: ["/"],
        properties: {
          context: "default",
          uri: "hotwire://fragment/web",
          pull_to_refresh_enabled: true
        }
      }
    ]
  }.freeze

  def android
    render json: PATH_CONFIGURATION
  end
end
