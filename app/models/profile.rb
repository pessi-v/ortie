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
class Profile < ApplicationRecord
  MIN_AGE = 18

  belongs_to :user

  enum :gender, {
    woman:     0,
    man:       1,
    nonbinary: 2,
    other:     3
  }

  validates :display_name, presence: true
  validates :birthdate, presence: true
  validates :gender, presence: true
  validate :must_be_of_age

  # Age is derived from birthdate — never stored, so it can't go stale.
  def age
    return if birthdate.blank?

    today = Date.current
    today.year - birthdate.year - (today.strftime("%m%d") < birthdate.strftime("%m%d") ? 1 : 0)
  end

  private

  def must_be_of_age
    return if birthdate.blank?

    errors.add(:birthdate, "must be at least #{MIN_AGE} years ago") if age < MIN_AGE
  end
end
