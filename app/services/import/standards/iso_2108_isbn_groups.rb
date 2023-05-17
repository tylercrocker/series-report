class Import::Standards::Iso2108IsbnGroups < Import::Base
  PROCESS_METHOD = :process_xml

  # https://www.isbn-international.org/range_file_generation
  # Last generated: Thu, 11 May 2023 23:39:48 BST
  def initialize file_path = File.join(Rails.root, 'lib', 'assets', 'isbn_group_ranges.xml'), sub_file = false
    super(file_path, sub_file)
  end

  def import_object xml
    # The first child is just the element list
    group_data = xml.xpath('//ISBNRangeMessage//RegistrationGroups//Group')
    group_data.each do |group_xml|
      ean, group_code = group_xml.xpath('Prefix').text.split('-')
      group_name = group_xml.xpath('Agency').text
      klass = if ean == '979'
        IsbnGroup::National
      elsif group_name.end_with?(' language')
        IsbnGroup::LanguageArea
      elsif group_name.start_with?('former ') || ['976', '982'].include?(group_code)
        IsbnGroup::Regional
      elsif ['92', '99902', '99951'].include?(group_code)
        IsbnGroup::Other
      else
        IsbnGroup::National
      end

      self.import_rules(group_xml, klass, ean, group_code, group_name)
    end

    self.create_unallocated_records
  end

  def import_rules group_xml, klass, ean, group_code, group_name
    group_xml.xpath('Rules//Rule').each do |rule|
      publisher_length = rule.xpath('Length').text.to_i
      range_start, range_end = rule.xpath('Range').text.split('-')

      # These are only created during import processes, so I'm not worried about race conditions
      record = klass.where(
        ean: ean,
        group: group_code,
        name: group_name,
        publisher_length: publisher_length,
        range_start: range_start,
        range_end: range_end
      ).first_or_create!

      record.item_length = publisher_length.zero? ? nil : (9 - group_code.length - publisher_length)

      record.determine_language

      record.save!
    end
  end

  def create_unallocated_records
    [
      64,
      (66..69).to_a,
      610,
      (632..639).to_a,
      990,
      9910,
      99900,
      99907,
      99991,
      (99993..99999).to_a
    ].flatten.each do |group_code|
      # I don't need to worry about race conditions because this only happens during import
      group = IsbnGroup.where(ean: '978', group: group_code.to_s).first_or_initialize
      next unless group.new_record?

      group.type = 'IsbnGroup::Unallocated'
      group.name = 'Unallocated'
      group.publisher_length = 0
      group.range_start = '0000000'
      group.range_end = '9999999'
      group.save!
    end
  end
end
