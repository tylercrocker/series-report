class IsbnGroup::National < IsbnGroup

  def determine_language
    case self.ean
    when '978'
      super unless self.determine_978_language
    when '979'
      super unless self.determine_979_language
    else
      super
    end
  end

  private

  def determine_978_language
    # TODO : let's try and find a "Country Name" -> "Language" file somewhere...
    # maybe if https://www.loc.gov/standards/ ever starts working again?
    false
  end

  def determine_979_language
    case self.group
    when '8'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'en'
    when '10'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'fr'
    when '11'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'ko'
    when '12'
      self.language_code_type = 'iso_639_1'
      self.language_code = 'it'
    else
      false
    end
  end
end