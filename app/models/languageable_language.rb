class LanguageableLanguage < ApplicationRecord
  belongs_to :languageable, polymorphic: true

  scope :join_languages, ->() do
    join('JOIN languages ON languages.iso_639_2 = languageable_languaes.iso_639_2')
  end

  def self.create_record! languageable, iso_639_2
    self.create_or_find_by(languageable: languageable, iso_639_2: iso_639_2)
  end

  def language in_lang: 'en'
    Language.where(name_lang: in_lang, iso_639_2: self.iso_639_2).first
  end
end
