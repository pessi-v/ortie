class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :reported, null: false, index: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :photo, null: true, foreign_key: { on_delete: :nullify }
      t.integer :reason, null: false
      t.text    :note
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :reports, :reported_id
    # Pending-review queue.
    add_index :reports, :status, where: "status = 0", name: "index_reports_pending"
  end
end
