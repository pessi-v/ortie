# == Schema Information
#
# Table name: profiles
#
#  id                    :bigint           not null, primary key
#  bio                   :text
#  birthdate             :date             not null
#  display_name          :string           not null
#  gender                :integer          not null
#  self_described_gender :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint           not null
#
# Indexes
#
#  index_profiles_on_bio_trgm           (bio) USING gin
#  index_profiles_on_display_name_trgm  (display_name) USING gin
#  index_profiles_on_user_id            (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
