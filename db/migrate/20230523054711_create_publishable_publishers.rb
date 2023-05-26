class CreatePublishablePublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :publishable_publishers do |t|
      t.references :publisher, null: false
      t.references :publishable, polymorphic: true, index: false, null: false

      t.timestamps
    end

    add_index :publishable_publishers, [:publishable_type, :publishable_id, :publisher_id], unique: true, name: 'publishable_publishers_unique_constraint'
  end
end
