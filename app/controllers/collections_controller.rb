class CollectionsController < ApplicationController
  before_action :determine_collection_class
  before_action :fetch_collection, only: [:show]

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
    return if @collection.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: { fields: @collection.editable_json }, template: false
      end
    end
  end

  private

  def determine_collection_class
    @collection_class = case params[:type]&.downcase
    when nil
      @collection_word = 'Collections'
      Collection
    when 'collection::series', 'series'
      @collection_word = 'Series'
      Collection::Series
    else
      if request.format == :json
        render json: {
          message: "Invalid collection type '#{params[:type]}'"
        }, status: 404
        return
      end

      nil
    end
  end

  def fetch_collection
    return if @collection_class.nil?

    begin
      @collection = @collection_class.where(slug: params[:slug]).first!
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html do
          raise 'I NEED TO REDIRECT OR SOMETHING?!'
        end
        format.json do
          render json: {
            message: "No #{@collection_class} found for `#{params[:slug]}`"
          }, status: 404
        end
      end
    end
  end
end
