class Collection < ApplicationRecord
  include Sluggable

  SLUGGABLE_FIELDS = [:title].freeze

  has_many :contained_relations, dependent: :destroy, class_name: 'CollectionItem'
  has_many :collection_items, as: :collection_itemable
  has_many :collections, through: :collection_items
  has_many :contributions, as: :contributable
  has_many :people, through: :contributions
  has_many :edit_requests, as: :editable, dependent: :destroy
  has_many :alternate_names, as: :nameable, dependent: :destroy

  scope :outer_joins_works, ->() do
    joins('LEFT OUTER JOIN collection_items ON collection_items.collection_id = collections.id AND collection_items.collection_itemable_type = \'Work\'')
  end

  scope :outer_joins_waiting_edit_requests, ->() do
    joins('LEFT OUTER JOIN edit_requests ON edit_requests.editable_type = \'Collection\' AND edit_requests.editable_id = collections.id AND edit_requests.status = 0') # 0 is waiting
  end

  scope :joins_creators, ->() do
    joins(:people).where(contributions: { type: Contribution::CREATOR_CLASSES.map(&:name) })
  end

  scope :joins_creators_and_contributors, ->() do
    joins(:people).where(contributions: { type: Contribution::SERIES_CLASSES.map(&:name) })
  end

  scope :by_creator, ->(person) do
    joins_creators.where(contributions: { person: person })
  end

  scope :by_creator_or_contributor, ->(person) do
    joins_creators_and_contributors.where(contributions: { person: person })
  end

  scope :by_title_caseless, ->(title) { where('LOWER(title) = ?', title.downcase) }

  def self.sort_scope(scope, sort:, direction:)
    case sort
    when 'creator'
      scope.joins_creators.group(:id, :title, 'people.name').order(Arel.sql("people.name #{direction}"))
    when 'num_nested'
      scope.joins(:contained_relations).order(Arel.sql("COUNT(*) FILTER (WHERE collection_items.collection_itemable_type = 'Collection') #{direction}"))
    when 'num_works'
      scope.joins(:contained_relations).order(Arel.sql("COUNT(*) FILTER (WHERE collection_items.collection_itemable_type = 'Work') #{direction}"))
    else
      scope.order(title: direction)
    end
  end

  def self.find_or_create_by_scope(scope, title)
    scope.by_title_caseless(title).first  || scope.create(title: title)
  end

  def self.find_or_create_by_scope!(scope, title)
    scope.by_title_caseless(title).first  || scope.create!(title: title)
  end

  def find_similar
    self.class.by_title_caseless(self.title).where.not(id: self.id).order(:slug)
  end

  def add_item item, position: nil, position_extra: nil
    record = self.initialize_contained_item(item, position: position, position_extra: position_extra)
    record.new_record? ? record.save : false
  end

  def add_item! item, position: nil, position_extra: nil
    record = self.initialize_contained_item(item, position: position, position_extra: position_extra)
    record.new_record? ? record.save! : false
  end

  def contained_items
    contained_relations.map(&:item)
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
        value: self.description,
        required: false
      },
      # contributors: {
      #   editable: true,
      #   type: 'array',
      #   value: self.people.map(&:editable_json)
      # },
      last_updated: {
        editable: false,
        type: 'timestamp',
        value: self.updated_at
      }
    }
  end

  def custom_edit_alternate_names data
    data.each do |key, value|
      if key.start_with?('new_')
        # TODO : handle existing, same-named items
        self.alternate_names.create!(name: value['name']['to'], language: value['language']['to'])
        next
      end

      existing = self.alternate_names.where(id: key).first
      next if existing.nil?

      value.each do |field, from_to|
        # TODO : handle cases where the name was changed by another request
        existing.send("#{field}=", from_to['to'])
      end
      existing.save!
    end
  end

  private

  def initialize_contained_item item, position:, position_extra:
    self.contained_relations.where(collection_itemable: item, position: position, position_extra: position_extra).first_or_create
  end
end
