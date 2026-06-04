class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.citext  :email, null: false
      t.string  :password_digest, null: false
      t.boolean :donor, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :message_preference, null: false, default: 0
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string  :location_label
      t.integer :pending_likes_count, null: false, default: 0
      t.datetime :last_active_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :last_active_at

    # Proximity index over active users only. Built on the earthdistance
    # ll_to_earth() expression so `earth_box`/`earth_distance` queries use it.
    # Raw SQL (functional index) — wrapped so the migration stays reversible;
    # on rollback the index is dropped together with the table.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX index_users_on_earth_location
            ON users USING gist (ll_to_earth(latitude, longitude))
            WHERE active AND latitude IS NOT NULL AND longitude IS NOT NULL;
        SQL
      end
    end
  end
end
