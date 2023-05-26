class Work < ApplicationRecord
  include AlternateNameable
  include Authorable
  include Identifiable
  include JsonDatable
  include Sluggable

  SLUGGABLE_FIELDS = [:title].freeze

  has_many :collection_items, as: :collection_itemable
  has_many :collections, through: :collection_items
  has_many :editions
  has_many :edit_requests, as: :editable, dependent: :destroy
  has_many :subjectable_subjects, as: :subjectable, dependent: :destroy
  has_many :subjects, through: :subjectable_subjects

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
        displayable: self.sti_type.titleize
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
        required: true
      },
      alternate_names: {
        editable: true,
        type: 'array[table]',
        # NOTE : the headers HAVE to be ordered properly!
        headers: ['Alternate Titles', 'Language'],
        value: self.alternate_names.map(&:editable_json)
      },
      description: {
        editable: true,
        type: 'text',
        value: self.ol_description,
        required: false
      },
      year_published: {
        editable: true,
        type: 'integer',
        value: self.year_published,
        required: true
      },
      published_on: {
        editable: true,
        type: 'date',
        value: self.published_on,
        required: false
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
