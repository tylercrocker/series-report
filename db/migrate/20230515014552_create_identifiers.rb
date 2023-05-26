class CreateIdentifiers < ActiveRecord::Migration[7.0]
  def change
    create_table :identifiers do |t|
      t.references :identifiable, index: true, null: false, polymorphic: true
      t.string :type, null: false
      t.string :identifier, null: false

      t.datetime :source_last_modified

      t.timestamps
    end

    add_index :identifiers, [:type, :identifier], unique: true, name: 'identifiers_unique_constraint'
  end
end
