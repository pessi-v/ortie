class MakePhotoPositionDeferrable < ActiveRecord::Migration[8.1]
  # Replace the plain unique index on (user_id, position) with a deferrable
  # unique constraint so "make primary" can permute positions within a single
  # transaction without tripping uniqueness mid-statement.
  def up
    remove_index :photos, column: %i[user_id position]
    execute <<~SQL
      ALTER TABLE photos
        ADD CONSTRAINT photos_user_position_unique
        UNIQUE (user_id, position) DEFERRABLE INITIALLY IMMEDIATE;
    SQL
  end

  def down
    execute "ALTER TABLE photos DROP CONSTRAINT photos_user_position_unique;"
    add_index :photos, %i[user_id position], unique: true
  end
end
