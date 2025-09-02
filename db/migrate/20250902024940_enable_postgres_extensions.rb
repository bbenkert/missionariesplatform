class EnablePostgresExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto'
    enable_extension 'citext'
    enable_extension 'unaccent'
    enable_extension 'pg_trgm'
  end
end