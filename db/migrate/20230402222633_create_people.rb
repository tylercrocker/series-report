class CreatePeople < ActiveRecord::Migration[7.0]
  def change
    create_table :people do |t|
      t.string :slug, index: { unique: true, name: 'people_unique_constraint' }

      t.string :name, index: true, null: false
      t.string :name_last_first, index: true, null: false

      t.text :bio

      t.timestamps
    end

    create_table :contributions do |t|
      t.string :type, null: false
      t.references :person, foreign_key: { on_delete: :restrict }, index: false, null: false
      t.references :contributable, index: false, null: false, polymorphic: true

      t.timestamps
    end

    add_index :contributions, [:contributable_id, :contributable_type, :person_id, :type], unique: true, name: 'contributions_unique_constraint'

    create_table :alternate_names do |t|
      t.references :nameable, index: false, null: false, polymorphic: true
      t.string :name
      t.string :language

      t.timestamps
    end

    add_index :alternate_names, [:nameable_type, :nameable_id, :name, :language], unique: true, name: 'alternate_names_unique_constraint'
  end
end
