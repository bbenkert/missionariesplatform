class RemoveContentFromMissionaryUpdates < ActiveRecord::Migration[8.0]
  def change
    remove_column :missionary_updates, :content, :text
  end
end
