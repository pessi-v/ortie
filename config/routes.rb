Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resource :onboarding, only: %i[show create], controller: "onboarding"

  resources :conversations, only: :show do
    resources :messages, only: :create
  end

  resources :photos, only: %i[create destroy]
  patch "photos/:id/make_primary" => "photos#make_primary", as: :make_primary_photo

  get   "settings"             => "settings#show",              as: :settings
  patch "settings/profile"     => "settings#update_profile",     as: :settings_profile
  patch "settings/preferences" => "settings#update_preferences", as: :settings_preferences
  patch "settings/location"    => "settings#update_location",    as: :settings_location
  patch "settings/account"     => "settings#update_account",     as: :settings_account
  patch "settings/active"      => "settings#update_active",       as: :settings_active

  # Discovery sections
  get "liked"     => "discovery#liked"
  get "passed"    => "discovery#passed"
  get "matches"   => "discovery#matches"
  get "likes-you" => "discovery#likes_you", as: :likes_you

  # Per-profile actions (large stroke-icon buttons on each card)
  post "profiles/:id/like"   => "likes#create",   defaults: { kind: "like" }, as: :like_profile
  post "profiles/:id/pass"   => "likes#create",   defaults: { kind: "pass" }, as: :pass_profile
  post "profiles/:id/unpass" => "likes#destroy",  as: :unpass_profile
  post "profiles/:id/flag"   => "reports#create", as: :flag_profile

  # Hotwire Native path configuration — the remote source of truth the mobile
  # apps fetch at launch (each app also bundles a local copy as a fallback).
  # Versioned so a breaking change can ship android_v2 without stranding old
  # installs. See android/README.md.
  get "configurations/android_v1" => "configurations#android", defaults: { format: :json }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "discovery#new_profiles"
end
