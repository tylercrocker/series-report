class Work::Book < Work
  DATA_SETTERS = {
    'description=': {
      type: String
    },
    'first_sentence=': {
      type: String
    },
    'ol_cover_ids=': {
      type: Array,
      contents: {
        type: Integer
      }
    },
    'ol_cover_edition_id=': {
      type: String # I'm going to trust these for now...
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
    },
    'ol_series=': {
      type: Array,
      contents: {
        type: String
      }
    },
    'processed_series=': {
      type: Array,
      contents: {
        type: Hash,
        structure: {
          name: {
            type: String
          },
          position: {
            type: String
          }
        }
      }
    }
  }.freeze
  DATA_ACCESSORS = DATA_SETTERS.keys.map{ |key| key.to_s.delete('=').to_sym }.freeze

  has_many :editions, class_name: 'Edition::Book', foreign_key: :work_id

  scope :joins_authors, ->() do
    joins(:people).where(contributions: { type: Contribution::AUTHOR_CLASSES.map(&:name) })
  end

  scope :with_ol_series, ->(size=nil) {
    res = where("data->'ol_series' IS NOT NULL")
    res = res.where("json_array_length(works.data->'ol_series') = ?", size) if size
    res
  }

  def self.process_series
    self.with_ol_series(1).find_each do |work|
      work.ol_series = [work.ol_series.first.delete("\u001A").strip]
      split_data = work.ol_series.first.match(/^\((?<position>\d+)\)$/) unless work.ol_series.nil?
      work.processed_series = [{ position: split_data[:position] }]
      work.save!
    end
  end

  def self.sort_scope(scope, sort:, direction:)
    case sort
    when 'author'
      scope.joins_authors.order(Arel.sql("people.name #{direction}"))
    else
      super
    end
  end
end
