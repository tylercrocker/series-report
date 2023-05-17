class IsbnGroup::LanguageArea < IsbnGroup

  def determine_language
    case self.ean
    when '978'
      super unless self.determine_978_language
    when '979'
      super
    else
      super
    end
  end

  private

  def determine_978_language
    case self.name
    when 'English language'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'en'
    when 'French language'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'fr'
    when 'German language'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'de'
    else
      false
    end
  end
end