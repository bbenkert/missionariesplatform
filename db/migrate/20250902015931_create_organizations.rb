class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.jsonb :settings, default: {}
      t.string :contact_email

      t.timestamps
    end
    add_index :organizations, :slug, unique: true
    add_index :organizations, :name
    add_index :organizations, :settings, using: :gin
  end
end
