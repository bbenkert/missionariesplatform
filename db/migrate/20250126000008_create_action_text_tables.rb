class CreateActionTextTables < ActiveRecord::Migration[8.0]
  def change
    # Use Action Text's install generator migration
    unless table_exists?(:action_text_rich_texts)
      create_table :action_text_rich_texts do |t|
        t.string     :name, null: false
        t.text       :body
        t.references :record, null: false, polymorphic: true, index: false

        if connection.supports_datetime_with_precision?
          t.timestamps precision: 6
        else
          t.timestamps
        end

        t.index [ :record_type, :record_id, :name ],
                name: "index_action_text_rich_texts_uniqueness",
                unique: true
      end
    end
  end
end
