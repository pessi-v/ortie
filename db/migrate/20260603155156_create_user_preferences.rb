class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :age_min, null: false, default: 18
      t.integer :age_max, null: false, default: 99
      t.integer :max_distance_km, null: false, default: 50
      t.integer :sought_genders, array: true, null: false, default: []

      t.timestamps
    end

    add_index :user_preferences, :sought_genders, using: :gin
    add_check_constraint :user_preferences, "age_min <= age_max", name: "age_range_ordered"
  end
end
