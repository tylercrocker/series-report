class CreateEditions < ActiveRecord::Migration[7.0]
  def change
    create_table :editions do |t|
      t.references :work, foreign_key: { on_delete: :restrict }, index: false, null: false
      t.string :type, null: false
      t.string :slug, null: false
      t.string :title, null: false

      t.text :notes
      t.json :data

      t.timestamps
    end

    add_index :editions, [:work_id, :type, :slug], unique: true, name: 'editions_unique_constraint'

    create_table :edition_identifiers do |t|
      t.references :edition, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.string :type, null: false
      t.string :identifier, null: false

      t.timestamps
    end

    add_index :edition_identifiers, [:identifier, :type], unique: true, name: 'edition_identifiers_unique_constraint'
  end
end
