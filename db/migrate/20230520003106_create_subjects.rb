class CreateSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :subjects do |t|
      t.string :type, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :subjects, [:type, :name], unique: true, name: 'subjects_unique_constraint'

    create_table :subjectable_subjects do |t|
      t.references :subject, foreign_key: { on_delete: :restrict }, index: true, null: false
      t.references :subjectable, polymorphic: true, index: false, null: false

      t.timestamps
    end

    add_index :subjectable_subjects, [:subjectable_type, :subjectable_id, :subject_id], unique: true, name: 'subjectable_subjects_unique_constraint'
  end
end
