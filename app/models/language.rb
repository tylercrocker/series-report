class Language < ApplicationRecord
  has_many :languageable_languages, foreign_key: 'iso_639_2', dependent: :destroy

  scope :in_english, ->() { where(name_lang: 'en') }
  scope :in_french, ->() { where(name_lang: 'gr') }
  scope :in_german, ->() { where(name_lang: 'de') }
end