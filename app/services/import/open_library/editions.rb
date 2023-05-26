class Import::OpenLibrary::Editions < Import::OpenLibrary
  FILE_NAME_SECTION = 'editions'.freeze
  OBJECT_CLASS = Edition::Book
  NAME_FIELD = 'title'.freeze

  def initialize file_path: '/Users/Tyler/Downloads/series-report/ol_dump_editions_latest.txt', sub_file: false
    PublisherIsbnRegistration.update_all(open_library_uses: 0) unless sub_file
    @test_record = Edition::Book.new

    super(file_path: file_path, sub_file: sub_file)
  end

  def process delete_file: false
    super(delete_file: delete_file)
  end

  def validate_object json
    return if super(json).nil?

    # If the edition is missing works, physical format, or publishers we can just leave, we don't care about those editions
    return if json.exclude?('"works":') || json.exclude?('"physical_format":') || json.exclude?('"publishers":')

    # We also don't care if we're entirely missing ISBNs
    return if json.exclude?('"isbn_13":') && json.exclude?('"isbn_10":')

    # Now we're going to have to parse the JSON out, this is the first big performance hit
    json = JSON.parse(json)

    # Just double checking... we might've had the key(s) but no value
    return if json['works'].blank? || json['physical_format'].blank? || json['publishers'].blank?
    return if json['isbn_13'].blank? && json['isbn_10'].blank?

    begin
      @test_record.binding_type = json['physical_format']
    rescue Edition::Book::UnknownBindingTypeError
      # We only allow specific binding types and I'm only handling those via a set of regexps in the standardizer
      return
    end

    @isbn13s = Set.new
    @isbn10s = Set.new
    [json['isbn_10'] || json['isbn_13']].flatten.compact.each do |isbn|
      @isbn13s << isbn if isbn.length == 13
      @isbn10s << isbn if isbn.length == 10
    end

    begin
      @isbn13s = @isbn13s.map{ |isbn| Identifier::Isbn13.isbn_parts(isbn) }
      @isbn10s = @isbn10s.map{ |isbn| Identifier::Isbn10.isbn_parts(isbn) }
    rescue Identifier::InvalidIdentifierError, IsbnGroup::UnallocatedPublisherError, IsbnGroup::Unallocated::Error, IsbnGroup::FailedToFindError
      # From what I can tell, records with invalid ISBNs are just kinda junk data, we can ignore them.
      return
    end

    # There aren't many, but there are some editions with multiple work records.
    # It appears we can just use the first one without any worries
    @work = Work::Book.by_open_library_id(json['works'].first['key']).first

    # If we don't have the work then we're running the importers out of order or we removed the work for some other reason.
    # In either case let's skip the edition.
    return if @work.nil?

    @creation_params = { work: @work } # we need this in the parent creation method

    json
  end

  # https://openlibrary.org/type/edition
  # works[] of type /type/work
  # title of type /type/string
  # subtitle of type /type/string
  # other_titles[] of type /type/string
  # authors[] of type /type/author
  # by_statement of type /type/string
  # publish_date of type /type/string
  # copyright_date of type /type/string
  # edition_name of type /type/string
  # languages[] of type /type/language
  # description of type /type/text
  # notes of type /type/text
  # genres[] of type /type/string
  # series[] of type /type/string
  # physical_dimensions of type /type/string
  # weight of type /type/string
  # physical_format of type /type/string
  # number_of_pages of type /type/int
  # pagination of type /type/string
  # subjects[] of type /type/string
  # isbn_10[] of type /type/string
  # isbn_13[] of type /type/string
  # lccn[] of type /type/string
  # ocaid of type /type/string
  # oclc_numbers[] of type /type/string
  # dewey_decimal_class[] of type /type/string
  # lc_classifications[] of type /type/string
  # contributions[] of type /type/string
  # publish_places[] of type /type/string
  # publishers[] of type /type/string
  # first_sentence of type /type/text
  # uris[] of type /type/string
  # uri_descriptions[] of type /type/string
  #
  # Fields that look internal:
  # scan_on_demand of type /type/boolean
  # collections[] of type /type/collection
  # source_records[] of type /type/string
  # scan_records[] of type /type/scan_record
  #
  # Fields that just don't look useful, usually seldom filled out
  # location[] of type /type/string
  # title_prefix of type /type/string
  # work_titles[] of type /type/string
  # translation_of of type /type/string -- most (about 2/3) are just the title of the work
  # publish_country of type /type/string -- most (~50k or ~70k) are "nyu" which isn't even a country?
  # table_of_contents[] of type /type/toc_item -- 36,655 records, not exactly sure what I'd do with this data
  # translated_from[] of type /type/language -- I'm not using this yet, it's a list of language types tho, same as languages, indicates the original language of the work. I don't feel like there's enough of it to be super useful yet tho (15,966 records)
  #
  # Fields that are never used:
  # distributors[] of type /type/string
  # volumes[] of type /type/volume
  # accompanying_material of type /type/string
  def update_record edition, json, last_modified
    @isbn13s.each do |isbn|
      edition.add_identifier!(Identifier::Isbn13, isbn)
    end

    @isbn10s.each do |isbn|
      edition.add_identifier!(Identifier::Isbn10, isbn)
    end

    # TODO : I need to ensure I can validate these first, they DO come as an array and can have multiple
    # https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/080Analytics/080Shared_Dimensions/040LC_Classifications
    # also do ocaid, lccn, and oclc_numbers
    # edition.add_identifier!(Identifier::LcClassifications, json['lc_classifications'].first)
    # edition.add_identifier!(Identifier::DeweyDecimalNumber, json['dewey_number'].first)

    edition.title = json['title'].squeeze(' ').strip
    edition.subtitle = json['subtitle']&.squeeze(' ')&.strip
    edition.binding_type = json['physical_format']
    edition.by_statement = json['by_statement']

    edition.num_pages = json['number_of_pages']
    if edition.num_pages.nil? && json['pagination'].present? && json['pagination'].match?(/^\d+\s?[p]?\.?(\s?[:;]?\s?ill\.?)?$/i)
      edition.num_pages = json['pagination'].to_i
      # json['pagination'] also has some information about number of volumes, if it's illustrated, and a few other things
      # There are only about 60-70k records with this, so for now I'm just using it to help fill out num_pages
    end

    json['other_titles']&.each do |alt_title|
      fixed_alt_title = alt_title.squeeze(' ').strip
      AlternateName.find_or_create_by(nameable: edition, name: fixed_alt_title) unless fixed_alt_title == edition.title
    end

    edition.description = json['description'].is_a?(Hash) ? json['description']['value'] : json['description']
    edition.first_sentence = json['first_sentence'].is_a?(Hash) ? json['first_sentence']['value'] : json['first_sentence']
    edition.ol_notes = json['notes'].is_a?(Hash) ? json['notes']['value'] : json['notes']
    # There appears to be an issue with a special whitespace character that doesn't get matched with \s
    # Just want to ensure it doesn't cause issues down the line.
    edition.ol_series = json['series']&.delete("\u001A")&.strip
    edition.ol_contributions = json['contributions']
    edition.publish_places = json['publish_places']
    edition.edition = json['edition_name']
    edition.dimensions = json['physical_dimensions']
    edition.weight = json['weight']

    json['publishers'].to_a.each do |pub_name|
      next if pub_name.blank?

      publisher = Publisher.create_or_find_by!(name: pub_name.squeeze(' ').strip)

      [@isbn13s, @isbn10s].flatten.each do |isbn|
        pub_ident = PublisherIsbnRegistration.create_or_find_by!(publisher: publisher, ean: isbn[:ean] || '978', group: isbn[:group].group, number: isbn[:publisher])
        PublisherIsbnRegistration.update_counters(pub_ident.id, { open_library_uses: 1 })
      end

      edition.publishers << publisher unless edition.publishers.include?(publisher)
    end

    links = []
    link_descs = json['uri_descriptions'] || []
    (json['uris'] || []).compact.each_with_index do |uri, i|
      links << { title: link_descs[i] || uri, url: uri }
    end
    edition.links = links

    if json['copyright_date'].present?
      dates = json['copyright_date'].gsub(/\D/, ' ').squeeze(' ').strip
      dates = dates.split(' ').select{ |date| date.length == 4 }.map(&:to_i).sort
      edition.copyright_years = dates
    end

    add_publish_date(edition, json['publish_date'])
    add_author_contributions(edition, json['authors'])
    add_languages(edition, json['languages'])
    add_subjects(edition, {
      Subject::OpenLibrary::Subject => json['subjects']&.reject{ |s| s.start_with?('nyt:') },
      Subject::OpenLibrary::Nyt => json['subjects']&.select{ |s| s.start_with?('nyt:') }&.map{ |s| s.sub(/^nyt:/, '') },
      Subject::OpenLibrary::Genre => json['genres']
    })

    begin
      super(edition, json, last_modified)
    rescue
      binding.pry
    end
  end

end
