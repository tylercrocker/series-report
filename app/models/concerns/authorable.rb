module Authorable
  extend ActiveSupport::Concern

  included do
    has_many :contributions, as: :contributable
    has_many :people, through: :contributions
  end

  def best_author_for_search
    contribs = contributions.preload(:person).authors.group_by(&:type)
    
    # These have a priority to their order, so we want to check them in that order.
    # Ideally we could just sort them that way in SQL but Postgres doesn't have the same field sorting that MySQL has.
    Contribution::AUTHOR_CLASSES.each do |author_class|
      authors = contribs[author_class.to_s]
      next if authors.blank?

      if authors.size == 1
        return authors.first.person
      else
        # TODO : let's try to determine a better way to do this...
        # Technically if there's co-authors we could use either, so maybe it doesn't matter?
        return authors.first.person
      end
    end
  end

end
