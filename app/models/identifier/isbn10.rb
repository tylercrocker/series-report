class Identifier::Isbn10 < Identifier
  
  CHECKSUM_REGEXP = /(?<checksum>\d|X)$/.freeze
  GROUP_REGEXP_PARTS = [
    /^(?<group>[0-5]|7)(?<extra>\d{8})/, # 0–5 OR 7 +8
    /^(?<group>6[0-3]\d)(?<extra>\d{6})/, # 600–639 +6
    /^(?<group>6[4-9])(?<extra>\d{7})/, # 64–69 +7
    /^(?<group>8\d|9[0-4])(?<extra>\d{7})/, # 80–94 +7
    /^(?<group>9[5-8]\d|990)(?<extra>\d{6})/, # 950–990 +6
    /^(?<group>99[1-8]\d)(?<extra>\d{5})/, # 9910–9989 +5
    /^(?<group>999\d{2})(?<extra>\d{4})/ # 99900–99999 +4
  ].freeze
  GROUP_REGEXP = /#{GROUP_REGEXP_PARTS.join("#{CHECKSUM_REGEXP}|")}/.freeze

  def self.invalid_identifier? identifiable, the_identifier
    return true if super(identifiable, the_identifier)

    # ISBNs are only valid for books editions!
    return true unless identifiable.is_a?(Edition::Book)

    string_ident = the_identifier.to_s
    return true unless string_ident.match?(/^\d{9}(\d|X)$/i)

    total = 0
    string_ident.split('').first(9).each_with_index do |n, i|
      total += n.to_i * (i + 1)
    end
    checksum = total % 11
    if checksum == 10
      return true unless string_ident[9] == 'X'
    else
      return true unless string_ident[9].to_i == checksum
    end

    false
  end

  def self.isbn_parts the_isbn
    return if the_isbn.blank?

    group_res = the_isbn.match(GROUP_REGEXP)
    raise InvalidIdentifierError, "Invalid ISBN10: #{the_isbn}" if group_res.nil?

    res = { checksum: group_res[:checksum] }

    res[:group] = IsbnGroup.fetch(group: group_res[:group], publisher_code: group_res[:extra])
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
