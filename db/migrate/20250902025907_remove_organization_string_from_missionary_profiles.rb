class RemoveOrganizationStringFromMissionaryProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :missionary_profiles, :organization, :string
  end
end