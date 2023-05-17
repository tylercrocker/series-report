class CreatePublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :publishers do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :publishers, :name, unique: true, name: 'publishers_unique_constraint'

    create_table :publisher_isbn_registrations do |t|
      t.references :publisher, foreign_key: { on_delete: :restrict }, index: false, null: false

      t.string :ean, null: false
      t.string :group, null: false
      t.string :number, null: false

      t.integer :open_library_uses, default: 0

      t.timestamps
    end

    add_index :publisher_isbn_registrations, [:ean, :group, :number, :publisher_id], unique: true, name: 'publisher_isbn_registrations_unique_constraint'
  end
end
