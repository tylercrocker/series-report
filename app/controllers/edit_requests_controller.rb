class EditRequestsController < ApplicationController
  before_action :determine_editable
  before_action :fetch_edit_request, only: [:update]
  before_action :determine_request_type, only: [:create]

  def index
    return if @editable.nil?

    requests = @editable_class == :none ? EditRequest.waiting.preload(:editable) : @editable.edit_requests.waiting

    requests = requests.order(:status, :created_at).select(:id, :type, :source, :status, :request, :created_at).group_by do |req|
      if req.respond_to? :format_for_api
        req.format_for_api @editable_class == :none ? req.editable : @editable_class
      end
      req.type.sub('EditRequest::', '')
    end

    render json: { editRequests: requests }
  end

  def create
    return if @request_class.nil?

    edit_request = @request_class.new(editable: @editable, source: 'user', status: :waiting, request: {})

    params[:editable].each do |field_name, value|
      case field_name
      when 'alternate_names'
        value.each do |key, alt_value|
          if key == 'new'
            alt_value[:name].each_with_index do |new_name, i|
              # Don't accept blank names, obviously
              next if new_name.blank?

              edit_request.request[field_name] ||= { as: 'array[table]' }
              edit_request.request[field_name]["#{key}_#{i}"] = {
                name: { to: new_name },
                language: { to: alt_value[:language][i].blank? ? 'English' : alt_value[:language][i] }
              }
            end
          else
            existing_record = AlternateName.where(id: key).first
            # If someone already deleted the record let's ignore this
            next if existing_record.nil?

            # TODO : maybe pass back what it WAS...? If that doesn't match I could throw an error for race conditions... that would prevent creating a change to X and then someone goes to make a change to Y but the change to X gets made while they're creating the request... unlikely, but it's still a race condition to consider
            # Should also consider blank languages as if they were "English" (the default)
            next if existing_record.name == alt_value[:name] && existing_record.language == alt_value[:language]

            edit_request.request[field_name] ||= { as: 'array[table]' }
            edit_request.request[field_name][key] = {
              name: { from: existing_record.name, to: alt_value[:name] },
              language: { from: existing_record.language, to: alt_value[:language] }
            }
          end
        end
      else # Normal fields
        next if @editable.send(field_name).to_s == value.strip

        edit_request.request[field_name] = {
          from: @editable.send(field_name),
          to: value.strip
        }
      end
    end

    if edit_request.request.blank?
      render json: { success: false, message: 'nothing to save' }, status: 400
    elsif edit_request.save
      render json: { success: true }
    else
      render json: { success: false, errors: edit_request.errors }, status: 500
    end
  end

  def update
    return if @edit_request.nil?

    case params[:request_action]&.downcase
    when 'accept'
      @edit_request.status = :processing
    when 'ignore'
      @edit_request.status = :ignored
    when 'deny'
      @edit_request.status = :denied
    when nil
      render json: { message: 'Edit Request action is required!' }, status: 400
      return
    else
      render json: { message: "Invalid Edit Request action: '#{params[:request_action]}'" }, status: 400
      return
    end

    # I'm not sure how this would ever fail
    # let's just make it explode if it does so we can fix it tho!
    @edit_request.save!

    # TODO: error handling
    if @edit_request.processing?
      begin
        @edit_request.accept_edit_request!(params[:edit_request_data])
      rescue StandardError => e
        @edit_request.status = :waiting
        @edit_request.save!
        raise e
      end
    end

    render json: { success: true }
  end

  private

  def determine_editable
    if params[:editable_type].nil?
      @editable_class = :none
      return
    end

    @editable_class = case params[:editable_type].downcase
    when 'series'
      Collection::Series
    when 'book'
      Work::Book
    when 'person'
      Person
    else
      nil
    end

    if @editable_class.nil?
      render json: {
        message: "Invalid editable type: `#{params[:editable_type]}`"
      }, status: 400
      return
    end

    @editable = @editable_class.where(slug: params[:editable_slug]).first
    return unless @editable.nil?

    render json: {
      message: "No editable item of type `#{@editable_class.name}` found for slug `#{params[:editable_slug]}`"
    }, status: 400
  end

  def fetch_edit_request
    return if @editable.nil?

    @edit_request = @editable.edit_requests.waiting.find(params[:id])
    return unless @edit_request.nil?

    render json: { message: 'No edit request found!' }, status: 400
  end

  def determine_request_type
    return if @editable.nil?

    begin
      @request_class = "EditRequest::#{params[:request_type]}".classify.constantize
    rescue NameError
      render json: { message: "Invalid request type `#{params[:request_type]}`" }, status: 400
    end
  end
end
