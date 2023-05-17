class IsbnGroup::Unallocated < IsbnGroup
  # These are manually entered from Wikipedia

  class Error < StandardError;end

  def contains_publisher_code? _code
    raise Error, "#{self.ean}-#{self.group} is unallocated"
  end
end