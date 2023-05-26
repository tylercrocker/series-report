module Languageable
  extend ActiveSupport::Concern

  included do
    has_many :languageable_languages, as: :languageable, dependent: :destroy
  end

  def languages in_lang: 'en'
    self.languageable_languages.languages_in
  end

end
