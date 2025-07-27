class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.integer :role, default: 0
      t.integer :status, default: 0
      t.boolean :is_active, default: true
      t.string :password_reset_token
      t.datetime :password_reset_sent_at
      t.datetime :last_sign_in_at
      t.string :last_sign_in_ip

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :status
    add_index :users, :password_reset_token, unique: true
  end
end
