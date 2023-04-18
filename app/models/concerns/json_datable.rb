module JsonDatable
  extend ActiveSupport::Concern

  class InvalidTypeError < StandardError; end
  class InvalidEnumValueError < StandardError
    def initialize(value, enum)
      super("`#{value}` is an invalid enum value; accepted values are `#{enum.join(', ')}`")
    end
  end

  def method_missing(field, value=nil)
    self.data ||= {}
    return self.data[field] if self.class::DATA_ACCESSORS.include?(field)
    
    settings = self.class::DATA_SETTERS[field]
    return super if settings.nil?

    raise InvalidTypeError if settings[:type].blank? && settings[:type] != value.class
    raise InvalidEnumValueError.new(value, settings[:enum]) if settings[:enum].present? && settings[:enum].exclude?(value)

    self.data[field.to_s.sub(/=$/, '').to_sym] = value
  end
end