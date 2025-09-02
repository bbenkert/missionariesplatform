class RemovePrayerRequestsFromMissionaryProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :missionary_profiles, :prayer_requests, :text
  end
end