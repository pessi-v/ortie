class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  skip_before_action :require_onboarding
  before_action :require_nsfw_service

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      redirect_to onboarding_path, notice: "Welcome to Ortie — let's set up your profile."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Don't admit new users while photo moderation is offline — their first photo
  # couldn't be screened.
  def require_nsfw_service
    return if nsfw_available?

    @user ||= User.new
    flash.now[:alert] = "Sign-ups are paused right now — please try again later."
    render :new, status: :service_unavailable
  end

  def registration_params
    params.expect(user: %i[email password password_confirmation])
  end
end
