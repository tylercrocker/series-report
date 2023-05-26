module Identifiable
  extend ActiveSupport::Concern

  included do
    has_many :identifiers, as: :identifiable, dependent: :destroy

    scope :by_identifier, ->(id_class, ident) do
      joins(:identifiers).where(identifiers: {
        type: id_class.name,
        identifier: ident
      })
    end

    scope :by_goodreads_id, ->(ident) { by_identifier(Identifier::GoodreadsId, ident) }
    scope :by_isbn10, ->(ident) { by_identifier(Identifier::Isbn10, ident) }
    scope :by_isbn13, ->(ident) { by_identifier(Identifier::Isbn13, ident) }
    scope :by_library_thing_id, ->(ident) { by_identifier(Identifier::LibraryThingId, ident) }
    scope :by_open_library_id, ->(ident) { by_identifier(Identifier::OpenLibraryId, ident) }
    scope :by_lc_classification, ->(ident) { by_identifier(Identifier::LcClassification, ident) }
    scope :by_dewey_decimal_number, ->(ident) { by_identifier(Identifier::DeweyDecimalNumber, ident) }
  end

  def add_identifier!(id_class, the_identifier)
    return if id_class.invalid_identifier?(self, the_identifier)

    id_class.create_or_find_by!(identifiable: self, identifier: the_identifier)
  end

  def identifier_by_class id_class
    self.identifiers.where(type: id_class.name).first
  end

  def open_library_id
    self.identifier_by_class(Identifier::OpenLibraryId)
  end

end
