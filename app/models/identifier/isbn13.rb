class Identifier::Isbn13 < Identifier

  CHECKSUM_REGEXP = /(?<checksum>\d)$/.freeze
  GROUP_REGEXP_PARTS = [
    /^(?<ean>\d{3})(?<group>8)(?<extra>\d{8})/, # 8 +8
    /^(?<ean>\d{3})(?<group>1[0-2]\d)(?<extra>\d{7})/ # 10-12 +6
  ].freeze
  GROUP_REGEXP = /#{GROUP_REGEXP_PARTS.join("#{CHECKSUM_REGEXP}|")}/.freeze

  class UnsupportedPrefixError < StandardError; end
  class UnsupportedGroupError < StandardError; end

  def self.invalid_identifier? identifiable, the_identifier
    return true if super(identifiable, the_identifier)

    # ISBNs are only valid for books editions!
    return true unless identifiable.is_a?(Edition::Book)

    string_ident = the_identifier.to_s
    return true unless string_ident.match?(/^97(8|9)\d{10}$/)

    total = 0
    string_ident.split('').first(12).each_with_index do |n, i|
      total += i.even? ? n.to_i : (n.to_i * 3)
    end
    checksum = total % 10
    return true unless (checksum.zero? ? 0 : 10 - checksum) == string_ident[12].to_i

    false
  end

  def self.isbn_parts the_isbn
    return if the_isbn.blank?

    if the_isbn.start_with?('978')
      ary = the_isbn.split('')
      ean = ary.shift(3).join
      res = Identifier::Isbn10.isbn_parts(ary.join)
      return if res.nil?

      res[:ean] = ean
      return res
    end

    group_res = the_isbn.match(GROUP_REGEXP)
    raise InvalidIdentifierError, "Invalid ISBN13: #{the_isbn}" if group_res.nil?
    
    res = { ean: group_res[:ean], checksum: group_res[:checksum] }

    res[:group] = IsbnGroup.fetch(ean: res[:ean], group: group_res[:group], publisher_code: group_res[:extra])

    if res[:group].publisher_length.positive?
      extra_ary = group_res[:extra].split('')
      res[:publisher] = extra_ary.shift(res[:group].publisher_length).join
      res[:title] = extra_ary.join
    else
      res[:unknown] = group_res[:extra]
    end

    res
  end

  def isbn_parts
    self.class.isbn_parts(self.identifier)
  end
end
