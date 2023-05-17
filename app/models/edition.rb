class Edition < ApplicationRecord
  include Sluggable
  include Authorable

  SLUGGABLE_BY = [:work_id]

  belongs_to :work
  has_many :edition_identifiers
  has_many :api_fetches, as: :fetchable, dependent: :destroy

  scope :by_identifier, ->(id_class, ident) do
    joins(:edition_identifiers).where(edition_identifiers: {
      type: id_class.name,
      identifier: ident
    })
  end

  scope :without_goodreads_id, ->() do
    joins("LEFT OUTER JOIN edition_identifiers ON editions.id = edition_identifiers.edition_id AND edition_identifiers.type = 'Identifier::GoodreadsId'").where(edition_identifiers: { id: nil })
  end

  scope :by_isbns, ->(isbns) {
    joins(:edition_identifiers).where(edition_identifiers: {
      type: ['Identifier::Isbn10', 'Identifier::Isbn13'],
      identifier: isbns
    })
  }

  def fetch
    self.api_fetches.first.api_data_for_edition_title
  end

  def add_identifier!(id_class, the_identifier)
    return if id_class.invalid_identifier?(the_identifier)

    id_class.create_or_find_by!(edition: self, identifier: the_identifier)
  end
end
