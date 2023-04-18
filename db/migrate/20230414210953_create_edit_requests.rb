class CreateEditRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :edit_requests do |t|
      t.string :source, null: false # generation source: system/user/?
      t.bigint :created_by_id # If the source was a user this should be the id of the user
      t.string :type, null: false # item merge, field edit, etc
      t.references :editable, index: true, null: false, polymorphic: true # requested from

      t.integer :status

      t.json :request # what should happen "merge to X", "change title to Y", etc

      t.timestamps
    end
  end
end
