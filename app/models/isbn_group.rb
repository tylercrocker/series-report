class IsbnGroup < ApplicationRecord
  MAX_RANGE_LENGTH = 7

  class UnallocatedPublisherError < StandardError;end
  class FailedToFindError < StandardError;end

  scope :by_ean_and_group, ->(ean, group) do
    where(ean: ean, group: group)
  end
  scope :by_ean_group_and_length, ->(ean, group, publisher_length) do
    by_ean_and_group(ean, group).where(publisher_length: publisher_length)
  end

  # If no ean is passed it's because it was an ISBN10,
  # all of these groups are just stored under 978, so let's default it to that.
  def self.fetch ean: '978', group:, publisher_code:
    self.by_ean_group_and_length(ean, group, publisher_code.length).each do |possible|
      return possible if possible.contains_publisher_code?(publisher_code)
    end

    # In case the publisher code was actually just the remainder from parsing off the group
    # we need to just see if the remainder is in one of the sets and go from there
    self.by_ean_and_group(ean, group).each do |possible|
      return possible if possible.contains_publisher_code?(publisher_code)
    end

    # I'm not sure how this would ever be possible, but let's have a fallback just in case
    # The only way we can hit this is if we're literally missing an ISBN range rule
    item_length = 12 - ean.length + group.length + publisher_code.length
    raise FailedToFindError, "Could not find group for #{ean}-#{group}-#{publisher_code}#{item_length.positive? ? "-#{'x' * item_length}" : ''}-x"
  end

  def contains_publisher_code? code
    # Determine what length to use to check the range
    length = if self.publisher_length.zero?
      code.first(self.max_range_length).length
    elsif self.publisher_length != code.length
      # In this case we didn't have a publisher code,
      # we had the full extra as in the brackets ean-group-[xxx...]-checksum
      code.first(self.max_range_length).length
    else
      self.publisher_length
    end
    range = (self.range_start.first(length).to_i..self.range_end.first(length).to_i)

    # If we weren't even part of the range we can leave early
    # Because of how the data is stored it's very possible to have to loop over a few
    # We also need to ensure the code is never longer than 7 characters due to the above
    # special case
    return false unless range.member?(code.first(self.max_range_length).to_i)

    # If we existed in the range but the range doesn't have a length it's not an allocated range
    raise UnallocatedPublisherError, "#{self.ean}-#{self.group} has no allocated publisher codes in the range #{self.range_start}-#{self.range_end}" if self.publisher_length.zero?

    # Finally we know we were actually part of the group range and that we are in an allocated set
    true
  end

  def determine_language
    self.language_code_type = nil
    self.language_code = nil
  end

  private

  # The ranges don't include the 9th digit so if we're using the full extra
  # as described by the value in brackets ean-group-[xxx...]-checksum
  # we want to strip down the possible range length to what is even appropriate based on the group length
  def max_range_length
    @max_range_length ||= 8 - self.group.length
    @max_range_length
  end
end