class CreateIsbnGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :isbn_groups do |t|
      # Not indexing this, it's not part of the unique constraint
      # It's just a descriptor to separate class functions
      # I can't think of a reason I'd ever filter on it directly except during model creation
      t.string :type, null: false

      t.string :ean, null: false
      t.string :group, null: false
      t.string :name, null: false

      t.integer :publisher_length, null: false
      t.string :range_start, null: false
      t.string :range_end, null: false
      t.integer :item_length

      t.string :language_code_type
      t.string :language_code

      t.timestamps
    end

    add_index :isbn_groups, [:ean, :group, :publisher_length, :name, :range_start, :range_end], unique: true, name: 'isbn_groups_unique_constraint'

    self.up_only do
      Import::Standards::Iso2108IsbnGroups.new.process(delete_file: false)
    end
  end
end
