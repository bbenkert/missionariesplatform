class AddTrigramIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :missionary_profiles, :slug, using: :gin, opclass: :gin_trgm_ops, name: 'index_missionary_profiles_on_slug_trgm'
    add_index :organizations, :slug, using: :gin, opclass: :gin_trgm_ops, name: 'index_organizations_on_slug_trgm'
    add_index :organizations, :name, using: :gin, opclass: :gin_trgm_ops, name: 'index_organizations_on_name_trgm'
  end
end