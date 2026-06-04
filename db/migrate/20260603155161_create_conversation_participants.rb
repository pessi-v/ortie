class CreateConversationParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer  :unread_count, null: false, default: 0
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :conversation_participants, [:conversation_id, :user_id], unique: true
  end
end
