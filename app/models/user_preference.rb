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
class UserPreference < ApplicationRecord
  belongs_to :user

  validates :age_min, :age_max, :max_distance_km, presence: true
  validates :age_min, numericality: { greater_than_or_equal_to: Profile::MIN_AGE }
  validate :age_range_ordered

  # Genders this user wants to see, as Profile.genders enum names.
  def sought_gender_names
    Profile.genders.invert.values_at(*sought_genders).compact
  end

  private

  def age_range_ordered
    return if age_min.blank? || age_max.blank?

    errors.add(:age_max, "must be greater than or equal to minimum age") if age_max < age_min
  end
end
