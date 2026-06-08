# == Schema Information
#
# Table name: conversation_participants
#
#  id              :bigint           not null, primary key
#  last_read_at    :datetime
#  unread_count    :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_conversation_participants_on_conversation_id_and_user_id  (conversation_id,user_id) UNIQUE
#  index_conversation_participants_on_user_id                      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class ConversationParticipantTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
