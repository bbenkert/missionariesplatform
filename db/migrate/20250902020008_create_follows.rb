class CreateFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :followable, polymorphic: true, null: false
      t.boolean :notifications_enabled, default: true

      t.timestamps
    end
    
    # Enforce uniqueness - one follow per user per followable
    add_index :follows, [:user_id, :followable_type, :followable_id], unique: true, name: 'index_follows_on_user_and_followable'
    add_index :follows, [:followable_type, :followable_id]
  end
end
