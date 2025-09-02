class UpdateMissionaryProfilesForSpec < ActiveRecord::Migration[8.0]
  def change
    add_column :missionary_profiles, :slug, :string
    add_column :missionary_profiles, :sensitive_flag, :boolean, default: false
    add_column :missionary_profiles, :public_profile_level, :integer, default: 0
    add_column :missionary_profiles, :pseudonym, :string
    add_column :missionary_profiles, :public_region, :string
    add_column :missionary_profiles, :safety_options, :jsonb, default: {}
    add_reference :missionary_profiles, :organization, foreign_key: true
    
    add_index :missionary_profiles, :slug, unique: true
    add_index :missionary_profiles, :sensitive_flag
    add_index :missionary_profiles, :public_profile_level
    add_index :missionary_profiles, :safety_options, using: :gin
  end
end
