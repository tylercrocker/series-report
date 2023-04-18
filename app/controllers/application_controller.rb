class ApplicationController < ActionController::Base
  include Pagy::Backend

  private

  def sort_direction default=:asc
    params[:dir]&.upcase == (default == :asc ? 'DESC' : 'ASC') ? 'DESC' : 'ASC'
  end
end
