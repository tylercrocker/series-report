class EditionIdentifier::Isbn10 < EditionIdentifier

  def invalid_identifier? the_identifier
    super(the_identifier) || the_identifier.to_s.length != 10
  end
end
