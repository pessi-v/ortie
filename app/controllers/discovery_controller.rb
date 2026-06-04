class DiscoveryController < ApplicationController
  def new_profiles
    @section = :new_profiles
    @profiles = discovery.new_profiles
  end

  def liked
    @section = :liked
    @profiles = discovery.liked
  end

  def passed
    @section = :passed
    @profiles = discovery.passed
  end

  def matches
    @section = :matches
    @matches = discovery.matches
  end

  def likes_you
    @section = :likes_you
    @profiles = discovery.likes_you
  end

  private

  def discovery
    @discovery ||= Discovery.new(Current.user)
  end
end
