# == Schema Information
#
# Table name: matches
#
#  id           :bigint           not null, primary key
#  confirmed_at :datetime
#  status       :integer          default("confirmed"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  initiator_id :bigint           not null
#  receiver_id  :bigint           not null
#
# Indexes
#
#  index_matches_initiator_confirmed  (initiator_id) WHERE (status = 1)
#  index_matches_on_user_pair         (LEAST(initiator_id, receiver_id), GREATEST(initiator_id, receiver_id)) UNIQUE
#  index_matches_receiver_confirmed   (receiver_id) WHERE (status = 1)
#
# Foreign Keys
#
#  fk_rails_...  (initiator_id => users.id) ON DELETE => cascade
#  fk_rails_...  (receiver_id => users.id) ON DELETE => cascade
#
require "test_helper"

class MatchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
