class EditionIdentifier::Isbn13 < EditionIdentifier

  def invalid_identifier? the_identifier
    super(the_identifier) || the_identifier.to_s.length != 13
  end
end
