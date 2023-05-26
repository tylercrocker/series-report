class CreateLanguages < ActiveRecord::Migration[7.0]
  def change
    create_table :languages do |t|
      t.string :iso_639_2, null: false, index: true
      t.string :iso_639_2_type # NULL, bibliographic, or terminology
      t.string :iso_639_1, index: true

      t.string :name_lang, null: false
      t.string :name, index: true, null: false
      t.string :name_qualifier

      t.timestamps
    end

    add_index :languages, [:iso_639_2, :name_lang]
    add_index :languages, [:name_lang, :name, :iso_639_2], unique: true, name: 'languages_unique_constraint'

    self.up_only do
      Import::Standards::Iso639Languages.new.process(delete_file: false)
    end

    create_table :languageable_languages do |t|
      t.string :iso_639_2, null: false, index: false
      t.references :languageable, polymorphic: true, null: false, index: false

      t.timestamps
    end

    add_index :languageable_languages, [:languageable_type, :languageable_id, :iso_639_2], unique: true, name: 'languagable_languages_unique_constraint'
  end
end
