class CreateLanguages < ActiveRecord::Migration[7.0]
  def change
    create_table :languages do |t|
      t.string :iso_639_2, null: false
      t.string :iso_639_2_type
      t.string :iso_639_1, index: true

      t.string :name_lang, null: false
      t.string :name, index: true, null: false
      t.string :name_qualifier

      t.timestamps
    end

    add_index :languages, [:iso_639_2, :iso_639_2_type], name: 'languages_iso_lookup'
    add_index :languages, [:name_lang, :name, :iso_639_2, :iso_639_2_type], unique: true, name: 'languages_unique_constraint'

    self.up_only do
      Importers::Standards::Iso639Languages.new.process
    end
  end
end
