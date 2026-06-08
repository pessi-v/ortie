# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE), not null
#  donor               :boolean          default(FALSE), not null
#  email               :citext           not null
#  last_active_at      :datetime
#  latitude            :decimal(10, 6)
#  location_label      :string
#  longitude           :decimal(10, 6)
#  message_preference  :integer          default("no_preference"), not null
#  password_digest     :string           not null
#  pending_likes_count :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_earth_location  (ll_to_earth((latitude)::double precision, (longitude)::double precision)) WHERE (active AND (latitude IS NOT NULL) AND (longitude IS NOT NULL)) USING gist
#  index_users_on_email           (email) UNIQUE
#  index_users_on_last_active_at  (last_active_at)
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
