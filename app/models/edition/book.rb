class Edition::Book < Edition
  include JsonDatable

  class UnknownBindingTypeError < StandardError; end

  DATA_SETTERS = {
    'binding_type=': {
      type: String,
      standardizer: :standardize_binding
    },
    'description=': {
      type: String
    },
    'first_sentence=': {
      type: String
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
    'weight=': {
      type: String # might be neat to break this into a hash...? It's also just not super important
    },
    'by_statement=': {
      type: String
    },
    'copyright_years=': {
      type: Array,
      contents: {
        type: Integer
      }
    },
    'publish_places=': {
      type: Array,
      contents: {
        type: String
      }
    },
    'ol_contributions=': {
      type: Array,
      contents: {
        type: String
      }
    },
    'ol_notes=': {
      type: String
    },
    # Let's store the raw data from OL but we'll also want a post-processor for works that standardizes the data
    'ol_series=': {
      type: Array,
      contents: {
        type: String
      }
    },
    'links=': {
      type: Array,
      contents: {
        type: Hash,
        structure: {
          title: {
            type: String
          },
          url: {
            type: URI
          }
        }
      }
    }
  }.freeze
  DATA_ACCESSORS = DATA_SETTERS.keys.map{ |key| key.to_s.delete('=').to_sym }.freeze

  scope :with_ol_series, ->() {
    where("data->'ol_series' IS NOT NULL")
  }

  # This is a helper method, possibly temporary
  # It's just for pulling ol_series data from editions up to the work for consolidation and processing
  def self.process_ol_series_data
    self.with_ol_series.preload(:work).find_each do |book|
      book.work.ol_series = ((book.work.ol_series || []) + book.ol_series).uniq
      book.work.save
    end
  end

  def self.standardize_binding the_binding
    raise UnknownBindingTypeError, 'No binding type given' if the_binding.blank?

    cleaned_binding = the_binding.downcase.strip.sub(/\s+[\/:;=,?]$/, '').gsub(/^(\[|\()|\]|\)$/, '')

    return 'Kindle Edition' if cleaned_binding.match?(/kindle/)
    return 'Audio' if cleaned_binding.match?(/^audio|^mp3 cd|audiobook|audio player/)
    return 'Hardcover' if cleaned_binding.match?(/hard\s?(cover|back|bound)|board\s?book/)
    return 'Turtleback' if cleaned_binding.match?(/turtle/)
    return 'Mass Market Paperback' if cleaned_binding.match?(/ma?ss\s*market/)
    return 'Paperback' if cleaned_binding.match?(/(soft|paper)\s*(cover|back)|paperb|trade\s+(soft|paper)/)
    return 'Leather Bound' if cleaned_binding.match?(/leather/)
    return 'Ebook' if cleaned_binding.match?(/e-?book/)
    return 'Bunkobon' if cleaned_binding.match?(/bunko/)
    return 'School/Library Binding'if cleaned_binding.match?(/(school|library|textbook)\s*binding|^textbook/)
    return 'Pop-Up' if cleaned_binding.match?(/pop-?up/)
    return 'Comic Book' if cleaned_binding.match?(/comic/)
    return 'Graphic Novel' if cleaned_binding.match?(/^graphics?\n*novel/)
    return 'Ring Bound' if cleaned_binding.match?(/ring bound/)
    return 'Spiral Bound' if cleaned_binding.match?(/spiral bound/)
    return 'Calendar' if cleaned_binding.match?(/calendar/)
    return 'Magazine' if cleaned_binding.match?(/magazine/)
    return 'Unbound' if cleaned_binding.match?(/unbound/)

    raise UnknownBindingTypeError, "#{the_binding} is disallowed and will prevent import"
  end

  def self.standardize_msrp the_msrp
    return if the_msrp.nil?

    the_msrp.to_f.positive? ? the_msrp.to_f : nil
  end
end
