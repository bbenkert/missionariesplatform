# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def self.up
    change_table :users do |t|
      ## Database authenticatable
      # t.string :email,              null: false, default: "" # Already exists
      # t.string :encrypted_password, null: false, default: "" # Will rename password_digest

      ## Recoverable
      # t.string   :reset_password_token # Already exists as password_reset_token
      # t.datetime :reset_password_sent_at # Already exists

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      # t.integer  :sign_in_count, default: 0, null: false # Already exists as last_sign_in_at, last_sign_in_ip
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at # Already exists
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip # Already exists

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps null: false
    end

    # Rename existing columns to match Devise conventions
    rename_column :users, :password_digest, :encrypted_password
    rename_column :users, :password_reset_token, :reset_password_token
    rename_column :users, :password_reset_sent_at, :reset_password_sent_at
    rename_column :users, :last_sign_in_at, :current_sign_in_at # Devise uses current_sign_in_at for last_sign_in_at
    rename_column :users, :last_sign_in_ip, :current_sign_in_ip # Devise uses current_sign_in_ip for last_sign_in_ip

    # Add new columns required by Devise that don't have existing counterparts
    add_column :users, :sign_in_count, :integer, default: 0, null: false

    # Remove existing indexes that Devise will recreate or are no longer needed
    remove_index :users, :email if index_exists?(:users, :email)
        remove_index :users, :password_reset_token if index_exists?(:users, :password_reset_token) # This was correct for the old name
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token) # Added this line for the new name

    # Add Devise-specific indexes
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end

  def self.down
    # Revert changes in reverse order
    remove_index :users, :reset_password_token
    remove_index :users, :email

    remove_column :users, :sign_in_count

    rename_column :users, :current_sign_in_ip, :last_sign_in_ip
    rename_column :users, :current_sign_in_at, :last_sign_in_at
    rename_column :users, :reset_password_sent_at, :password_reset_sent_at
    rename_column :users, :reset_password_token, :password_reset_token
    rename_column :users, :encrypted_password, :password_digest

    change_table :users do |t|
      # Add back columns removed by Devise if necessary, or handle manually
      # t.string :email,              null: false, default: ""
      # t.string :password_digest, null: false, default: ""
    end
  end
end