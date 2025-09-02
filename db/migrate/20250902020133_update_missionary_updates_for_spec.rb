class UpdateMissionaryUpdatesForSpec < ActiveRecord::Migration[8.0]
  def change
    add_column :missionary_updates, :visibility, :integer, default: 0
    add_column :missionary_updates, :tsvector, :tsvector
    
    add_index :missionary_updates, :visibility
    add_index :missionary_updates, :tsvector, using: :gin
  end
end
