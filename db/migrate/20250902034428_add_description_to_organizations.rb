class AddDescriptionToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :description, :text
  end
end
