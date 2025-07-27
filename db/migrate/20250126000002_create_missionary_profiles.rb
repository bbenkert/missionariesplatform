class CreateMissionaryProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :missionary_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :bio
      t.string :ministry_focus
      t.string :organization
      t.string :country
      t.string :city
      t.text :prayer_requests
      t.text :giving_links
      t.string :website_url
      t.string :social_media_links
      t.date :started_ministry_at
      t.text :ministry_description
      t.boolean :accepting_messages, default: true

      t.timestamps
    end

    add_index :missionary_profiles, :country
    add_index :missionary_profiles, :organization
    add_index :missionary_profiles, :ministry_focus
  end
end
