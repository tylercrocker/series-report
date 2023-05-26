module JsonDatable
  extend ActiveSupport::Concern

  class InvalidTypeError < StandardError
    def initialize(field, klass, value)
      super("#{field}: `#{value}` is of type #{value.class} but only type #{klass} is accepted")
    end
  end

  class InvalidEnumValueError < StandardError
    def initialize(field, value, enum)
      super("#{field}: `#{value}` is an invalid enum value; accepted values are `#{enum.join(', ')}`")
    end
  end

  def method_missing(field, the_value=nil)
    self.data ||= {}
    return self.data[field] || self.data[field.to_s] if self.class::DATA_ACCESSORS.include?(field)
    
    settings = self.class::DATA_SETTERS[field]
    return super if settings.nil?

    value = self.data_standardizer(field, settings, the_value)

    if value.blank?
      self.data.delete(field.to_s.delete('='))
    else
      self.data[field.to_s.delete('=')] = value.respond_to?(:strip) ? value.strip : value
    end
  end

  def data_standardizer field, settings, the_value
    # Run over any custom data standardizers we have defined
    value = self.class.send(settings[:standardizer], the_value) if settings[:standardizer].present?
    value ||= the_value

    # Do any general standardization we can, this is mostly for numbers.
    if value.present? && value.class != settings[:type]
      # These are really silly comparisons, but they work
      case settings[:type].to_s
      when 'Integer'
        raise InvalidTypeError.new(field, settings[:type], the_value) unless value.to_i.to_s == value.to_s.strip

        value = value.to_i
      when 'Float'
        # floats in ruby are dumb...
        raise InvalidTypeError.new(field, settings[:type], the_value) unless value.to_f.to_s == value.to_s.strip.sub(/\.00+$/, '.0')

        value = value.to_f
      when 'URI'
        begin
          uri = Addressable::URI.parse(value)
          # If it doesn't look like a URI let's just skip it
          value = uri.host.nil? ? nil : uri.to_s
        rescue Addressable::URI::InvalidURIError
          # Failed URI parsing can just be skipped, I don't want to mess with that for now
        end
      else
        raise InvalidTypeError.new(field, settings[:type], the_value)
      end
    end

    # Validate enum restrictions
    raise InvalidEnumValueError.new(field, the_value, settings[:enum]) if settings[:enum].present? && settings[:enum].exclude?(value)

    # Handle collection data, this is a recursive call.
    case settings[:type].to_s
    when 'Array'
      value = self.evaluate_data_array(field, settings, value)
    when 'Hash', 'Set' # are there any others?
      # In this case it's cause I've defined a type but haven't written the validator yet.
      raise "UNSUPPORTED COLLECTION DATA TYPE #{settings[:type]}"
    end

    # Finally return the evaluated and corrected value for storage
    value
  end

  def evaluate_data_array field, settings, the_value
    return if the_value.blank?

    case settings[:contents][:type].to_s
    when 'String', 'Integer', 'Float'
      the_value.each_with_index do |arr_val, i|
        # Be careful with this, only direct assignments or it may cause looping issues
        the_value[i] = self.data_standardizer("#{field}[#{i}]", settings[:contents], arr_val)
      end
    when 'Hash'
      the_value.each_with_index do |the_arr_val, i|
        arr_val = if the_arr_val.is_a?(Hash)
          the_arr_val
        else
          begin
            # Let's TRY to parse it as JSON to see if we get lucky...
            JSON.parse(the_arr_val)
          rescue JSON::ParserError
            raise InvalidTypeError.new("#{field}[#{i}]", settings[:contents][:type], arr_val)
          end
        end
  
        # We'll need to store any errant keys we don't want for later removal.
        errant_keys = []

        arr_val.each do |arr_val_key, arr_val_val|
          arr_val_settings = settings[:contents][:structure][arr_val_key.to_sym]
          if arr_val_settings.nil?
            errant_keys << arr_val_key
            next
          end

          new_val = self.data_standardizer("#{field}[#{i}][#{arr_val_key}]", arr_val_settings, arr_val_val)
          if new_val.blank?
            errant_keys << arr_val_key # We can count blank values as errant, we never want to store empty data.
          else
            arr_val[arr_val_key] = new_val
          end
        end

        # Finally just remove any keys we didn't want
        errant_keys.each do |errant_key|
          arr_val.delete(errant_key)
        end
      end
    else
      # In this case it's cause I've defined a type but haven't written the validator yet.
      raise "UNSUPPORTED DATA TYPE IN ARRAY #{settings[:contents][:type]}"
    end

    the_value.compact.reject{ |v| v.blank? }
  end
end