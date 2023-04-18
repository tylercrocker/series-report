class WorksController < ApplicationController
  before_action :determine_work_class

  def index
    redirect_to works_path and return if @work_class.nil?

    @works = @work_class.sort_scope(@work_class, sort: params[:sort], direction: sort_direction)

    @pagy, @works = pagy(@works, items: 50)

    @contributions = Contribution.people_hash(:authors_for_works, @works.map(&:id))
  end

  def show

  end

  private

  def determine_work_class
    @work_class = case params[:type]
    when nil
      Work
    when 'books'
      Work::Book
    else
      nil
    end
  end

end
