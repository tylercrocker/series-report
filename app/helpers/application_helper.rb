require 'pagy/extras/bootstrap'

module ApplicationHelper
  include Pagy::Frontend

  def pagination_footer colspan: 1
    return nil if @pagy.pages.zero?

    content_tag :tfoot, class: 'table-pagination' do
      content_tag :tr do
        content_tag :td, colspan: colspan do
          concat raw(pagy_bootstrap_nav(@pagy))
        end
      end
    end
  end

  def sort_dir default=:asc
    params[:dir]&.upcase == (default == :asc ? 'DESC' : 'ASC') ? :asc : :desc
  end
end
