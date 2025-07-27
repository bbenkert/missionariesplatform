class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }, index: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }, index: true
      t.boolean :is_blocked, default: false
      t.datetime :blocked_at

      t.timestamps
    end

    add_index :conversations, [:sender_id, :recipient_id], unique: true
    add_index :conversations, :is_blocked
    add_index :conversations, :updated_at
  end
end
