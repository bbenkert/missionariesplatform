class AddSafetyModeToMissionaryProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :missionary_profiles, :safety_mode, :integer, default: 0, null: false
    add_index :missionary_profiles, :safety_mode
  end
end
