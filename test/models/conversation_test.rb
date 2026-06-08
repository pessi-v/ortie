# == Schema Information
#
# Table name: conversations
#
#  id              :bigint           not null, primary key
#  last_message_at :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  match_id        :bigint           not null
#
# Indexes
#
#  index_conversations_on_match_id  (match_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id) ON DELETE => cascade
#
require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
