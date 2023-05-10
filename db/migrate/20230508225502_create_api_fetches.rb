class CreateApiFetches < ActiveRecord::Migration[7.0]
  def change
    create_table :api_fetches do |t|
      t.string :type, null: false
      t.references :fetchable, index: false, null: false, polymorphic: true

      t.integer :status, default: 0, null: false
      t.datetime :last_fetched_at
      t.json :messages

      t.timestamps
    end

    add_index :api_fetches, [:type, :fetchable_type, :fetchable_id], unique: true, name: 'api_fetches_unique_constraint'
  end
end
