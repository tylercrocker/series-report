class Work < ApplicationRecord
  include Sluggable

  SLUGGABLE_FIELDS = [:title].freeze

  has_many :collection_items, as: :collection_itemable
  has_many :collections, through: :collection_items
  has_many :editions
  has_many :contributions, as: :contributable
  has_many :people, through: :contributions

  def self.sort_scope(scope, sort:, direction:)
    case sort
    when 'published'
      scope.order(year_published: direction)
    else
      scope.order(title: direction)
    end
  end
end
