class EditRequest::FieldsEdit < EditRequest
  def accept_edit_request! edit_request_data
    editable_json = self.editable.editable_json

    edit_request_data.each do |fieldName, _implicit_inclusion|
      next unless editable_json[fieldName.to_sym][:editable]

      case editable_json[fieldName.to_sym][:type]
      when 'string', 'text', 'integer', 'date'
        self.editable.send("#{fieldName}=", self.request[fieldName]['to'])
      else
        raise "UNIMPLEMENTED TYPE: #{editable_json[fieldName.to_sym][:type]} - #{self.request[fieldName]['to']}"
      end
    end

    # TODO : handle errors
    # TODO : handle more complex types (particularly nested data)

    self.editable.save!
  end
end
