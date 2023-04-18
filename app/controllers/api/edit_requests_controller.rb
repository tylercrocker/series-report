class Api::EditRequestsController < ApplicationController
  before_action :determine_editable
  before_action :fetch_edit_request, except: [:index]

  def index
    return if @editable.nil?

    requests = @editable.edit_requests.order(:status, :created_at).select(:id, :type, :source, :status, :request, :created_at).group_by do |req|
      req.format_for_api @editable_class
      req.type.sub('EditRequest::', '')
    end

    render json: { editRequests: requests }
  end

  def update
    return if @edit_request.nil?

    @edit_request.process_edit_request!(params[:edit_request_data])

    render json: { success: true }
  end

  private

  def determine_editable
    @editable_class = case params[:type].downcase
    when 'collection'
      Collection
    else
      nil
    end

    if @editable_class.nil?
      render json: {
        message: "Invalid editable type: `#{params[:type]}`"
      }, status: 400
      return
    end

    @editable = @editable_class.where(slug: params[:slug]).first
    return unless @editable.nil?

    render json: {
      message: "No editable item of type `#{@editable_class.name}` found for slug `#{params[:slug]}`"
    }, status: 400
  end

  def fetch_edit_request
    @edit_request = @editable.edit_requests.waiting.find(params[:id])
    return unless @edit_request.nil?

    render json: { message: "No edit request found!" }, status: 400
  end
end
