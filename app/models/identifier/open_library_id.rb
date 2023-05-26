class Identifier::OpenLibraryId < Identifier

  WORK_REGEX = /^\/works\/OL\d+W$/.freeze
  AUTHOR_REGEX = /^\/authors\/OL\d+A$/.freeze
  BOOK_REGEX = /^\/books\/OL\d+M$/.freeze

  def self.invalid_identifier? identifiable, the_identifier
    return true if super(identifiable, the_identifier)
    
    case identifiable.class.name
    when 'Work::Book'
      return true unless the_identifier.match?(WORK_REGEX)
    when 'Edition::Book'
      return true unless the_identifier.match?(BOOK_REGEX)
    when 'Person'
      return true unless the_identifier.match?(AUTHOR_REGEX)
    else
      return true # unsupported identifiable type
    end

    false
  end
end
