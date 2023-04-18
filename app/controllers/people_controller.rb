class PeopleController < ApplicationController
  before_action :determine_role

  def index
    redirect_to people_path and return if @people.nil?

    @people = Person.sort_scope(@people, sort: params[:sort], direction: sort_direction, role: params[:role])

    @pagy, @people = pagy(@people, items: 50)
  end

  def show

  end

  private

  def determine_role
    @people = case params[:role]
    when nil
      Person
    when 'authors'
      Person.with_author_roles.group(:id).select('people.*', 'COUNT(*) AS num_works')
    else
      nil
    end
  end
end
