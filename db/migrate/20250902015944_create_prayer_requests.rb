class CreatePrayerRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :prayer_requests do |t|
      t.references :missionary_profile, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.jsonb :tags
      t.integer :status, default: 0
      t.integer :urgency, default: 0
      t.datetime :published_at
      t.tsvector :tsvector

      t.timestamps
    end
    
    add_index :prayer_requests, :status
    add_index :prayer_requests, :urgency
    add_index :prayer_requests, :published_at
    add_index :prayer_requests, :tags, using: :gin
    add_index :prayer_requests, :tsvector, using: :gin
  end
end
