class CreateEditions < ActiveRecord::Migration[7.0]
  def change
    create_table :editions do |t|
      t.references :work, foreign_key: { on_delete: :restrict }, index: false, null: false
      t.string :type, null: false
      t.string :slug, null: false
      t.string :title, null: false
      t.string :subtitle

      t.integer :year_published
      t.integer :month_published
      t.date :published_on

      t.json :data

      t.timestamps
    end

    add_index :editions, [:work_id, :type, :slug], unique: true, name: 'editions_unique_constraint'
  end
end
