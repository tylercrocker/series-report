class CollectionsController < ApplicationController
  before_action :determine_collection_class

  def index
    redirect_to collections_path and return if @collection_class.nil?

    @collection_class = @collection_class.joins(:contained_relations).outer_joins_waiting_edit_requests.select('
      collections.*,
      COUNT(DISTINCT collection_items.id) FILTER (WHERE collection_items.collection_itemable_type = \'Collection\') AS num_nested,
      COUNT(DISTINCT collection_items.id) FILTER (WHERE collection_items.collection_itemable_type = \'Work\') AS num_works,
      COUNT(DISTINCT edit_requests.id) AS num_edit_reqs
    ').group('collections.id, collections.title')
    @collections = @collection_class.sort_scope(@collection_class, sort: params[:sort], direction: sort_direction)

    @pagy, @collections = pagy(@collections, items: 50)

    @contributions = Contribution.people_hash(:collection_contributors, @collections.map(&:id))
  end

  def show

  end

  private

  def determine_collection_class
    @collection_class = case params[:type]
    when nil
      @collection_word = 'Collections'
      Collection
    when 'series'
      @collection_word = 'Series'
      Collection::Series
    else
      nil
    end
  end

end
