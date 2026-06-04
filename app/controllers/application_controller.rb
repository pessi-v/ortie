class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_onboarding

  helper_method :nsfw_available?

  private

  # Cached per request. Drives the "paused" gating on sign-ups and photo uploads
  # when the NSFW moderation sidecar is down.
  def nsfw_available?
    return @nsfw_available unless @nsfw_available.nil?

    @nsfw_available = NsfwDetector.available?
  end

  # An authenticated user without a profile must finish onboarding before they
  # can reach discovery or act on anyone. Auth/onboarding controllers skip this
  # with `skip_before_action :require_onboarding`.
  def require_onboarding
    return unless authenticated?
    return if Current.user.profile.present?

    redirect_to onboarding_path
  end
end
