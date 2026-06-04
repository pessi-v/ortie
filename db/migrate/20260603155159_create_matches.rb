class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :initiator, null: false, index: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :receiver, null: false, index: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.integer  :status, null: false, default: 1 # confirmed
      t.datetime :confirmed_at

      t.timestamps
    end

    # Confirmed-match lookups from either side.
    add_index :matches, :initiator_id, where: "status = 1", name: "index_matches_initiator_confirmed"
    add_index :matches, :receiver_id, where: "status = 1", name: "index_matches_receiver_confirmed"
    add_check_constraint :matches, "initiator_id <> receiver_id", name: "no_self_match"

    # One match per unordered pair, regardless of who initiated. Functional
    # index (LEAST/GREATEST) — raw SQL, wrapped to stay reversible.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE UNIQUE INDEX index_matches_on_user_pair
            ON matches (LEAST(initiator_id, receiver_id), GREATEST(initiator_id, receiver_id));
        SQL
      end
    end
  end
end
