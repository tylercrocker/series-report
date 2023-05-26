class Identifier::GoodreadsId < Identifier

  def self.invalid_identifier? identifiable, the_identifier
    return true if super(identifiable, the_identifier)

    # Since Goodreads shuttered their API we currently only get Edition IDs from them via dump files.
    # Also I'm only supporting books for now, if something else comes up I can add it.
    return true unless identifiable.is_a?(Edition::Book)

    false
  end
end
