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
