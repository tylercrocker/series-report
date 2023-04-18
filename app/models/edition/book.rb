class Edition::Book < Edition
  include JsonDatable

  DATA_ACCESSORS = [:binding_type, :num_pages, :year_published, :published_date].freeze
  DATA_SETTERS = {
    "binding_type=": {
      type: String,
      enum: [
        'Audio',
        'Ebook',
        'Hardcover',
        'Library Binding',
        'Mass Market Paperback',
        'Paperback',
        'Unknown Binding'
      ]
    },
    "num_pages=": {
      type: Integer
    },
    "year_published=": {
      type: Integer
    },
    "published_date=": {
      type: Date
    }
  }.freeze
  SLUGGABLE_FIELDS = [:year_published, :binding_type].freeze

  scope :by_goodreads_id, ->(ident) { by_identifier(EditionIdentifier::GoodreadsId, ident) }
  scope :by_isbn10, ->(ident) { by_identifier(EditionIdentifier::Isbn10, ident) }
  scope :by_isbn13, ->(ident) { by_identifier(EditionIdentifier::Isbn13, ident) }
  scope :by_library_thing_id, ->(ident) { by_identifier(EditionIdentifier::LibraryThingId, ident) }
  scope :by_open_library_id, ->(ident) { by_identifier(EditionIdentifier::OpenLibraryId, ident) }

  def self.standardize_binding the_binding
    formatted_binding = the_binding&.strip&.squeeze(' ')&.titleize
    case the_binding
    when 'Audiobook', 'Audio Cassette', 'Audio CD'
      'Audio'
    when 'Kindle Edition'
      'Ebook'
    when 'Mss Market Paperback'
      'Mass Market Paperback'
    when 'School & Library Binding'
      'Library Binding'
    when '', nil
      'Unknown Binding'
    else
      formatted_binding
    end
  end
end
