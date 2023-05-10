class Edition::Book < Edition
  include JsonDatable

  DATA_SETTERS = {
    'binding_type=': {
      type: String,
      enum: [
        'Audio',
        'Ebook',
        'Hardcover',
        'Library Binding',
        'Mass Market Paperback',
        'Paperback',
        'Unbound',
        'Unknown Binding'
      ],
      standardizer: :standardize_binding
    },
    'num_pages=': {
      type: Integer
    },
    'year_published=': {
      type: Integer
    },
    'published_date=': {
      type: Date
    },
    'msrp=': {
      type: Float,
      standardizer: :standardize_msrp
    },
    'edition=': {
      type: String
    },
    'isbndb_image_url=': {
      type: String
    },
    'language=': {
      type: String
      # enum: [
      #   'en'
      #   # There will be more... let's see what we end up with first
      # ]
    },
    'dimensions=': {
      type: String # might be neat to break this into a hash...? It's also just not super important
    },
    'publisher=': {
      type: String # TODO : These should break into their own model.
    }
  }.freeze
  DATA_ACCESSORS = DATA_SETTERS.keys.map{ |key| key.to_s.delete('=').to_sym }.freeze
  SLUGGABLE_FIELDS = [:year_published, :binding_type].freeze

  scope :by_goodreads_id, ->(ident) { by_identifier(EditionIdentifier::GoodreadsId, ident) }
  scope :by_isbn10, ->(ident) { by_identifier(EditionIdentifier::Isbn10, ident) }
  scope :by_isbn13, ->(ident) { by_identifier(EditionIdentifier::Isbn13, ident) }
  scope :by_library_thing_id, ->(ident) { by_identifier(EditionIdentifier::LibraryThingId, ident) }
  scope :by_open_library_id, ->(ident) { by_identifier(EditionIdentifier::OpenLibraryId, ident) }

  def self.standardize_binding the_binding
    case the_binding
    when 'Audiobook', 'Audio Cassette', 'Audio CD', 'MP3 CD', 'DVD-ROM'
      'Audio'
    when 'Kindle Edition'
      'Ebook'
    when 'Mss Market Paperback'
      'Mass Market Paperback'
    when 'School & Library Binding'
      'Library Binding'
    when 'Perfect Paperback'
      'Paperback'
    when '', nil
      'Unknown Binding'
    else
      the_binding.strip.squeeze(' ').titleize
    end
  end

  def self.standardize_msrp the_msrp
    return if the_msrp.nil?

    the_msrp.to_f.positive? ? the_msrp.to_f : nil
  end
end
