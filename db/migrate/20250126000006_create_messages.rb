class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :sender, null: false, foreign_key: { to_table: :users }, index: true
      t.text :content
      t.datetime :read_at

      t.timestamps
    end

    add_index :messages, :read_at
    add_index :messages, :created_at
  end
end
