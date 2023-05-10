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

  scope :by_isbns, ->(isbns) {
    joins(:edition_identifiers).where(edition_identifiers: {
      type: ['EditionIdentifier::Isbn10', 'EditionIdentifier::Isbn13'],
      identifier: isbns
    })
  }

  def invalid_identifier? the_identifier
    the_identifier.blank?
  end

  def add_identifier(id_class, the_identifier)
    return if self.invalid_identifier?(the_identifier)

    id_class.create_or_find_by(edition: self, identifier: the_identifier)
  end

  def add_identifier!(id_class, the_identifier)
    return if self.invalid_identifier?(the_identifier)

    id_class.create_or_find_by!(edition: self, identifier: the_identifier)
  end
end
