class Edition::Book < Edition
  include JsonDatable

  DATA_SETTERS = {
    'binding_type=': {
      type: String,
      enum: [
        'Audio',
        'Ebook',
        'Kindle Edition',
        'Hardcover',
        'Library Binding',
        'Mass Market Paperback',
        'Paperback',
        'Unbound',
        'Unknown Binding',
        'Bunkobon'
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

  scope :by_goodreads_id, ->(ident) { by_identifier(Identifier::GoodreadsId, ident) }
  scope :by_isbn10, ->(ident) { by_identifier(Identifier::Isbn10, ident) }
  scope :by_isbn13, ->(ident) { by_identifier(Identifier::Isbn13, ident) }
  scope :by_library_thing_id, ->(ident) { by_identifier(Identifier::LibraryThingId, ident) }
  scope :by_open_library_id, ->(ident) { by_identifier(Identifier::OpenLibraryId, ident) }

  def self.standardize_binding the_binding
    case the_binding&.downcase
    when 'audiobook', 'audio cassette', 'audio cd', 'mp3 cd', 'dvd-rom'
      'Audio'
    when 'mss market paperback'
      'Mass Market Paperback'
    when 'school & library binding'
      'Library Binding'
    when 'perfect paperback'
      'Paperback'
    when 'paperback bunko'
      'Bunkobon'
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
