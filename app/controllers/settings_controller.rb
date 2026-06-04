class SettingsController < ApplicationController
  before_action :set_records

  def show
  end

  def update_profile
    ok = ActiveRecord::Base.transaction do
      @profile.update!(profile_params)
      @user.update!(message_preference: params.dig(:user, :message_preference))
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    if ok
      redirect_to settings_path(anchor: "profile"), notice: "Profile updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_preferences
    if @preference.update(preference_params)
      redirect_to settings_path(anchor: "preferences"), notice: "Preferences updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_location
    if @user.update(location_params)
      redirect_to settings_path(anchor: "location"), notice: "Location updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_account
    unless @user.authenticate(params.dig(:account, :current_password))
      flash.now[:alert] = "Current password is incorrect."
      return render :show, status: :unprocessable_entity
    end

    if @user.update(account_params)
      redirect_to settings_path(anchor: "account"), notice: "Account updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_active
    active = ActiveModel::Type::Boolean.new.cast(params[:active])
    @user.update!(active: active)
    notice = active ? "Account reactivated — you're visible again." : "Account deactivated — you're hidden from discovery."
    redirect_to settings_path(anchor: "account"), notice: notice
  end

  private

  def set_records
    @user = Current.user
    @profile = @user.profile
    @preference = @user.user_preference
  end

  def profile_params
    params.expect(profile: %i[display_name bio gender self_described_gender])
  end

  def preference_params
    prefs = params.expect(user_preference: [:age_min, :age_max, :max_distance_km, { sought_genders: [] }])
    prefs[:sought_genders] = Array(prefs[:sought_genders]).reject(&:blank?).map(&:to_i)
    prefs
  end

  def location_params
    params.expect(user: %i[latitude longitude location_label])
  end

  # Email always; password only when a new one was supplied.
  def account_params
    permitted = params.expect(account: %i[email password password_confirmation])
    permitted.delete(:password) if permitted[:password].blank?
    permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
    permitted
  end
end
