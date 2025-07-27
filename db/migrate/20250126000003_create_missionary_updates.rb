class CreateMissionaryUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :missionary_updates do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.text :content
      t.integer :update_type, default: 0
      t.integer :status, default: 0
      t.boolean :is_urgent, default: false
      t.string :tags
      t.datetime :published_at

      t.timestamps
    end

    add_index :missionary_updates, :update_type
    add_index :missionary_updates, :status
    add_index :missionary_updates, :is_urgent
    add_index :missionary_updates, :published_at
    add_index :missionary_updates, :tags
  end
end
