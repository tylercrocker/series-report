class Contribution < ApplicationRecord

  CREATOR_CLASSES = [
    Contribution::Creator,
    Contribution::CoCreator
  ].freeze
  SERIES_CLASSES = [
    Contribution::Creator,
    Contribution::CoCreator,
    Contribution::ContributingAuthor
  ].freeze
  BOOK_CLASSES = [
    Contribution::Author,
    Contribution::CoAuthor,
    Contribution::ContributingAuthor,
    Contribution::Creator,
    Contribution::EditingAuthor,
    Contribution::Illustrator
  ].freeze
  AUTHOR_CLASSES = [
    Contribution::Author,
    Contribution::CoAuthor,
    Contribution::Creator,
    Contribution::EditingAuthor
  ].freeze

  belongs_to :contributable, polymorphic: true
  belongs_to :person

  scope :authors, ->() { where(type: AUTHOR_CLASSES.map(&:name)) }
  scope :series_contributors, ->() { where(type: SERIES_CLASSES.map(&:name)) }
  scope :authors_for_works, ->(work_ids) do
    authors.where(contributable_type: 'Work', contributable_id: work_ids)
  end
  scope :collection_contributors, ->(collection_ids) do
    series_contributors.where(contributable_type: 'Collection', contributable_id: collection_ids)
  end

  def self.people_hash scope_name, object_ids
    Contribution.send(scope_name, object_ids).preload(:person).inject({}) do |h, contribution|
      h[contribution.contributable_id] ||= {}
      h[contribution.contributable_id][contribution.role] ||= []
      h[contribution.contributable_id][contribution.role] << contribution.person
      h
    end
  end

  def role
    self.class.name.sub('Contribution::', '')
  end
end
