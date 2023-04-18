class Edition < ApplicationRecord
  include Sluggable

  SLUGGABLE_BY = [:work_id]

  belongs_to :work
  has_many :edition_identifiers
  has_many :contributions, as: :contributable
  has_many :people, through: :contributions

  scope :by_identifier, ->(id_class, ident) do
    joins(:edition_identifiers).where(edition_identifiers: { type: id_class.name, identifier: ident })
  end

  def add_identifier(id_class, identifier)
    return false if identifier.blank?

    id_class.create_or_find_by(edition: self, identifier: identifier)
  end

  def add_identifier!(id_class, identifier)
    return false if identifier.blank?

    id_class.create_or_find_by!(edition: self, identifier: identifier)
  end
end
