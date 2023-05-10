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

    value = self.class.send(settings[:standardizer], the_value) if settings[:standardizer].present?
    value ||= the_value

    if settings[:type].present? && value.present? && value.class != settings[:type]
      # These are really silly comparisons, but they work
      case settings[:type].to_s
      when 'Integer'
        raise InvalidTypeError.new(field, settings[:type], the_value) unless value.to_i.to_s == value.to_s.strip

        value = value.to_i
      when 'Float'
        # floats in ruby are dumb...
        raise InvalidTypeError.new(field, settings[:type], the_value) unless value.to_f.to_s == value.to_s.strip.sub(/\.00+$/, '.0')

        value = value.to_f
      else
        raise InvalidTypeError.new(field, settings[:type], the_value)
      end
    end

    raise InvalidEnumValueError.new(field, the_value, settings[:enum]) if settings[:enum].present? && settings[:enum].exclude?(value)

    if value.blank?
      self.data.delete(field.to_s.delete('='))
    else
      self.data[field.to_s.delete('=')] = value.respond_to?(:strip) ? value.strip : value
    end
  end
end