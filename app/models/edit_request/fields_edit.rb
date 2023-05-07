class EditRequest::FieldsEdit < EditRequest
  def accept_edit_request! edit_request_data
    editable_json = self.editable.editable_json
    
    array_fields = {}

    edit_request_data.each do |the_field_name, _implicit_inclusion|
      field_name_data = the_field_name.split(/\]\[|\[|\]/)
      field_name = field_name_data.shift
      field_name_sym = field_name.to_sym
      next unless editable_json[field_name_sym][:editable]

      case editable_json[field_name_sym][:type]
      when 'string', 'text', 'integer', 'date'
        self.editable.send("#{field_name}=", self.request[field_name]['to'])
      when 'array[table]'
        array_fields[field_name] ||= {}
        field_key = field_name_data.shift
        array_fields[field_name][field_key] ||= {}
        inner_field_name = field_name_data.shift
        array_fields[field_name][field_key][inner_field_name] = self.request[field_name][field_key][inner_field_name]
        # This pulls the selected items out of the request's data
        # So it's filtered by what was input by the requester AND by what was checked by the accepter
        # For example, alternate_names ends up looking like this:
        # {'alternate_names' => {'new_0' => {'name' => {'to' => 'XYZ'}}}}
        # or for non-new values
        # {'alternate_names' => {123 => {'name' => {'from' => 'ZYX', 'to' => 'XYZ'}}}}
        # If a language is also passed (which would be normal) then it would modify that record to then look like this:
        # {'alternate_names' => {123 => {'name' => {'from' => 'ZYX', 'to' => 'XYZ'}, 'language' => {'from' => 'English', 'to' => 'Spanish'}}}}
        # Though in the case of alternate_names the language should rarely change
        # Another common array type would be "contributions"
      else
        raise "UNIMPLEMENTED TYPE: #{editable_json[field_name_sym][:type]} - #{self.request[field_name]['to']}"
      end
    end

    array_fields.each do |field_name, field_data|
      self.editable.send("custom_edit_#{field_name}", field_data)
    end

    # TODO : handle errors

    self.editable.save!
  end
end
