class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :liker, null: false, index: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :liked, null: false, index: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.integer :kind, null: false
      t.text    :intro_note

      t.timestamps
    end

    # One directed edge per pair; un-pass flips kind on the same row.
    add_index :likes, [:liker_id, :liked_id], unique: true
    add_index :likes, [:liked_id, :kind] # "Likes You" / who-passed-me
    add_index :likes, [:liker_id, :kind] # my liked / passed lists
    add_check_constraint :likes, "liker_id <> liked_id", name: "no_self_like"
  end
end
