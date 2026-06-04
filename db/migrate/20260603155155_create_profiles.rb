class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string  :display_name, null: false
      t.text    :bio
      t.date    :birthdate, null: false
      t.integer :gender, null: false
      t.string  :self_described_gender

      t.timestamps
    end

    # Fuzzy search (pg_trgm) on name and bio.
    add_index :profiles, :display_name, using: :gin, opclass: :gin_trgm_ops,
              name: "index_profiles_on_display_name_trgm"
    add_index :profiles, :bio, using: :gin, opclass: :gin_trgm_ops,
              name: "index_profiles_on_bio_trgm"
  end
end
