class Work < ApplicationRecord
  include Sluggable

  SLUGGABLE_FIELDS = [:title].freeze

  has_many :collection_items, as: :collection_itemable
  has_many :collections, through: :collection_items
  has_many :editions
  has_many :contributions, as: :contributable
  has_many :people, through: :contributions
  has_many :edit_requests, as: :editable, dependent: :destroy
  has_many :alternate_names, as: :nameable, dependent: :destroy

  scope :outer_joins_waiting_edit_requests, ->() do
    joins('LEFT OUTER JOIN edit_requests ON edit_requests.editable_type = \'Work\' AND edit_requests.editable_id = works.id AND edit_requests.status = 0') # 0 is waiting
  end

  def self.sort_scope(scope, sort:, direction:)
    case sort
    when 'year_published'
      scope.order(year_published: direction)
    when 'published_on'
      scope.order(published_on: direction)
    else
      scope.order(title: direction)
    end
  end

  def editable_json
    {
      type: {
        editable: false,
        type: 'class',
        value: self.type,
        displayable: self.sti_type
      },
      slug: {
        editable: false,
        type: 'path',
        value: self.slug
      },
      title: {
        editable: true,
        type: 'string',
        value: self.title,
        alternates: self.alternate_names.map(&:editable_json)
      },
      description: {
        editable: true,
        type: 'text',
        value: self.description
      },
      year_published: {
        editable: true,
        type: 'integer',
        value: self.year_published
      },
      published_on: {
        editable: true,
        type: 'date',
        value: self.published_on
      },
      # contributors: {
      #   editable: false,
      #   type: 'array',
      #   value: self.people
      # },
      last_updated: {
        editable: false,
        type: 'timestamp',
        value: self.updated_at
      }
    }
  end
end
