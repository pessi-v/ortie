class OnboardingController < ApplicationController
  skip_before_action :require_onboarding

  def show
    redirect_to root_path, notice: "Your profile is already set up." and return if onboarded?

    @profile = Current.user.build_profile
    @preference = Current.user.build_user_preference
  end

  def create
    redirect_to root_path and return if onboarded?

    @profile = Current.user.build_profile(profile_params)
    @preference = Current.user.build_user_preference(preference_params)
    Current.user.assign_attributes(location_params)

    if [@profile.valid?, @preference.valid?, Current.user.valid?].all?
      ActiveRecord::Base.transaction do
        @profile.save!
        @preference.save!
        Current.user.save!
      end
      redirect_to root_path, notice: "You're all set."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def onboarded?
    Current.user.profile.present?
  end

  def profile_params
    params.expect(profile: %i[display_name birthdate gender bio self_described_gender])
  end

  def preference_params
    prefs = params.expect(user_preference: [:age_min, :age_max, :max_distance_km, { sought_genders: [] }])
    prefs[:sought_genders] = Array(prefs[:sought_genders]).reject(&:blank?).map(&:to_i)
    prefs
  end

  def location_params
    params.expect(user: %i[latitude longitude location_label message_preference])
  end
end
