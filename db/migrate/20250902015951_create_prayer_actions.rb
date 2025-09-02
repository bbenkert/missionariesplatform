class CreatePrayerActions < ActiveRecord::Migration[8.0]
  def change
    create_table :prayer_actions do |t|
      t.references :prayer_request, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: false

      t.timestamps
    end
    
    # Enforce idempotency - one prayer per user per request
    add_index :prayer_actions, [:prayer_request_id, :user_id], unique: true
    add_index :prayer_actions, :user_id
    add_index :prayer_actions, :created_at
  end
end
