class Person < ApplicationRecord
  include Sluggable

  SLUGGABLE_FIELDS = [:name].freeze

  has_many :alternate_names, as: :nameable
  has_many :contributions
  has_many :contributables, through: :contributions
  has_many :edit_requests, as: :editable, dependent: :destroy

  scope :by_names, ->(names) do
    scope = joins(:alternate_names).where(name: names)
    scope = scope.or(joins(:alternate_names).where(name_last_first: names))
    scope.or(joins(:alternate_names).where(alternate_names: { name: names }))
  end

  scope :with_book_roles, ->() do
    joins(:contributions).where(contributions: {
      contributable_type: ['Work', 'Edition'],
      type: Contribution::BOOK_CLASSES.map(&:name)
    })
  end

  scope :with_author_roles, ->(contributable_type='Work') do
    joins(:contributions).where(contributions: {
      contributable_type: contributable_type,
      type: Contribution::AUTHOR_CLASSES.map(&:name)
    })
  end

  scope :outer_joins_waiting_edit_requests, ->() do
    joins('LEFT OUTER JOIN edit_requests ON edit_requests.editable_type = \'Person\' AND edit_requests.editable_id = people.id AND edit_requests.status = 0') # 0 is waiting
  end

  def self.sort_scope(scope, sort:, direction:, role: nil)
    case sort
    when 'num_works'
      return scope.order(Arel.sql("COUNT(*) #{direction}")) if role == 'authors'
    end

    scope.order(name: direction)
  end

  def editable_json
    {
      type: {
        editable: false,
        type: 'class',
        value: 'Person',
        displayable: 'Person'
      },
      slug: {
        editable: false,
        type: 'path',
        value: self.slug
      },
      name: {
        editable: true,
        type: 'string',
        value: self.name,
        required: true
      },
      name_last_first: {
        editable: false,
        type: 'string',
        value: self.name_last_first
      },
      alternate_names: {
        editable: true,
        type: 'array[table]',
        # NOTE : the headers HAVE to be ordered properly!
        headers: ['Alternate Names', 'Language'],
        value: self.alternate_names.map(&:editable_json)
      },
      bio: {
        editable: true,
        type: 'text',
        value: self.bio,
        required: false
      },
      # contributions: {
      #   editable: false,
      #   type: 'array',
      #   value: ???
      # },
      last_updated: {
        editable: false,
        type: 'timestamp',
        value: self.updated_at
      }
    }
  end

  def series_contribution_work_slugs series
    contributions.where(contributable_type: 'Work', type: Contribution::AUTHOR_CLASSES.map(&:name))
      .joins('JOIN works ON contributable_id = works.id').joins('JOIN collection_items ON collection_items.collection_itemable_type = \'Work\' AND collection_items.collection_itemable_id = contributions.contributable_id').where('collection_items.collection_id = ?', series.id).pluck(Arel.sql('DISTINCT works.slug'))
  end
end
