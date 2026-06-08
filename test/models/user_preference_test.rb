# == Schema Information
#
# Table name: user_preferences
#
#  id              :bigint           not null, primary key
#  age_max         :integer          default(99), not null
#  age_min         :integer          default(18), not null
#  max_distance_km :integer          default(50), not null
#  sought_genders  :integer          default([]), not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_user_preferences_on_sought_genders  (sought_genders) USING gin
#  index_user_preferences_on_user_id         (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
