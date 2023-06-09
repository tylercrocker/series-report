class CreateWorks < ActiveRecord::Migration[7.0]
  def change
    create_table :works do |t|
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

    add_index :works, [:type, :slug], unique: true, name: 'works_unique_constraint'
  end
end
