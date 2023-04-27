class WorksController < ApplicationController
  before_action :determine_work_class
  before_action :fetch_work, only: [:show]

  def index
    redirect_to works_path and return if @work_class.nil?

    @works = @work_class.sort_scope(@work_class, sort: params[:sort], direction: sort_direction)

    @works = @works.outer_joins_waiting_edit_requests.select('
      works.*,
      COUNT(DISTINCT edit_requests.id) AS num_edit_reqs
    ')

    @works = if params[:sort] == 'author'
      @works.group('works.id, works.title, works.year_published, works.published_on, people.name')
    else
      @works.group('works.id, works.title, works.year_published, works.published_on')
    end

    @pagy, @works = pagy(@works, items: 50)

    @contributions = Contribution.people_hash(:authors_for_works, @works.map(&:id))
  end

  def show
    return if @work.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: { fields: @work.editable_json }, template: false
      end
    end
  end

  private

  def determine_work_class
    @work_class = case params[:type]&.downcase
    when nil
      @work_word = 'Works'
      Work
    when 'books', 'book'
      @work_word = 'Books'
      Work::Book
    else
      if request.format == :json
        render json: {
          message: "Invalid work type '#{params[:type]}'"
        }, status: 404
        return
      end

      nil
    end
  end

  def fetch_work
    return if @work_class.nil?

    begin
      @work = @work_class.where(slug: params[:slug]).first!
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html do
          raise 'I NEED TO REDIRECT OR SOMETHING?!'
        end
        format.json do
          render json: {
            message: "No #{@work_class} found for `#{params[:slug]}`"
          }, status: 404
        end
      end
    end
  end

end
