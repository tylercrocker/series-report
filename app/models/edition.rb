class Edition < ApplicationRecord
  include Authorable
  include Identifiable
  include Languageable
  include Sluggable

  SLUGGABLE_BY = [:work_id].freeze
  SLUGGABLE_FIELDS = [:title].freeze
  MONTH_YEAR_REGEX = /^(january|february|march|april|may|june|july|august|september|october|november|december)\s\d+$/i

  belongs_to :work
  has_many :api_fetches, as: :fetchable, dependent: :destroy
  has_many :publishable_publishers, as: :publishable, dependent: :destroy
  has_many :publishers, through: :publishable_publishers
  has_many :subjectable_subjects, as: :subjectable, dependent: :destroy
  has_many :subjects, through: :subjectable_subjects

  scope :without_goodreads_id, ->() do
    joins("LEFT OUTER JOIN identifiers ON editions.id = identifiers.edition_id AND identifiers.type = 'Identifier::GoodreadsId'").where(identifiers: { id: nil })
  end

  scope :by_isbns, ->(isbns) {
    joins(:identifiers).where(identifiers: {
      type: ['Identifier::Isbn10', 'Identifier::Isbn13'],
      identifier: isbns
    })
  }

  def fetch
    self.api_fetches.first.api_data_for_edition_title
  end
end
