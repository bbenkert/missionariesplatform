class CreateEmailLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :email_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email_type, null: false
      t.string :resend_id, null: false
      t.datetime :sent_at
      t.datetime :bounced_at
      t.datetime :complained_at
      t.datetime :delivered_at
      t.jsonb :meta, default: {}

      t.timestamps
    end

    add_index :email_logs, :email_type
    add_index :email_logs, :resend_id, unique: true
    add_index :email_logs, :sent_at
    add_index :email_logs, :bounced_at
    add_index :email_logs, :complained_at
  end
end
