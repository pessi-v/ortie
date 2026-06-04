class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.integer :moderation_status, null: false, default: 0

      t.timestamps
    end

    add_index :photos, [:user_id, :position], unique: true
    # Manual-review queue: only rows awaiting review (moderation_status = 2).
    add_index :photos, :moderation_status, where: "moderation_status = 2",
              name: "index_photos_pending_review"
    add_check_constraint :photos, "position BETWEEN 1 AND 6", name: "position_within_range"
  end
end
