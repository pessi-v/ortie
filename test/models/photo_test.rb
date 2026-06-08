# == Schema Information
#
# Table name: photos
#
#  id                :bigint           not null, primary key
#  moderation_status :integer          default("pending"), not null
#  position          :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_photos_on_user_id      (user_id)
#  index_photos_pending_review  (moderation_status) WHERE (moderation_status = 2)
#  photos_user_position_unique  (user_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
