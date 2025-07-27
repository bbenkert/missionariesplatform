class CreateSupporterFollowings < ActiveRecord::Migration[8.0]
  def change
    create_table :supporter_followings do |t|
      t.references :supporter, null: false, foreign_key: { to_table: :users }, index: true
      t.references :missionary, null: false, foreign_key: { to_table: :users }, index: true
      t.boolean :is_active, default: true
      t.boolean :email_notifications, default: true

      t.timestamps
    end

    add_index :supporter_followings, [:supporter_id, :missionary_id], unique: true, name: 'index_supporter_followings_unique'
    add_index :supporter_followings, :is_active
  end
end
