ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # NSFW sidecar: never hit the network in tests. Reset before each test so a
    # test that flips these (to exercise the down / threshold paths) can't bleed.
    setup do
      NsfwDetector.service_available_override = true
      NsfwDetector.classification_override = :approved
    end

    # Add more helper methods to be used by all tests here...
  end
end
