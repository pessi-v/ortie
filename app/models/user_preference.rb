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
