class PeopleController < ApplicationController
  before_action :fetch_person, only: [:show]

  def index
    @people = case params[:role]
    when 'author', 'authors'
      Person.with_author_roles
    when nil, ''
      Person.joins(:contributions)
    else
      redirect_to people_path and return
    end

    @people = @people.outer_joins_waiting_edit_requests.group(:id).select('
      people.*,
      COUNT(DISTINCT contributions.contributable_id) FILTER (WHERE contributions.contributable_type = \'Work\') AS num_works,
      COUNT(DISTINCT edit_requests.id) AS num_edit_reqs
    ')

    @people = @people.sort_scope(@people, sort: params[:sort], direction: sort_direction, role: params[:role])

    @pagy, @people = pagy(@people, items: 50)
  end

  def show
    return if @person.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: { fields: @person.editable_json }, template: false
      end
    end
  end

  private

  def fetch_person
    begin
      @person = Person.where(slug: params[:slug]).first!
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html do
          raise 'I NEED TO REDIRECT OR SOMETHING?!'
        end
        format.json do
          render json: {
            message: "No person found for `#{params[:slug]}`"
          }, status: 404
        end
      end
    end
  end
end
