class Import::OpenLibrary::Publishers < Import::Base
  PROCESS_METHOD = :process_tsv

  # https://openlibrary.org/developers/dumps
  # Publisher data comes from the editions dump
  def initialize file_path = '/Users/Tyler/Downloads/series-report/ol_dump_editions_2023-04-30.txt', sub_file = false
    super(file_path, sub_file)
  end

  def process
    unless @sub_file
      puts "Clearing publisher use numbers..."
      PublisherIsbnRegistration.update_all(open_library_uses: 0)
    end

    super
  end

  # Array of the following
  # type - type of record (/type/edition, /type/work etc.)
  # key - unique key of the record. (/books/OL1M etc.)
  # revision - revision number of the record
  # last_modified - last modified timestamp
  # JSON - the complete record in JSON format
  def import_object values
    type, key, revision, last_modified, json = values
    json = JSON.parse(json)

    if json['publishers'].blank?
      # @messages[:missing_publishers] += 1
      return
    end

    begin
      isbn = if json['isbn_13']
        # @messages[:data_with_multiple_isbns] += 1 if json['isbn_13'].length > 1
        Identifier::Isbn13.isbn_parts(json['isbn_13'].first)
      elsif json['isbn_10']
        # @messages[:data_with_multiple_isbns] += 1 if json['isbn_10'].length > 1
        Identifier::Isbn10.isbn_parts(json['isbn_10'].first)
      end
    rescue Identifier::InvalidIdentifierError
      # @messages[:invalid_isbns] << (json['isbn_13']&.first || json['isbn_10']&.first)
      return
    rescue IsbnGroup::UnallocatedPublisherError
      # @messages[:unallocated_publisher_number] << (json['isbn_13']&.first || json['isbn_10']&.first)
      return
    rescue IsbnGroup::Unallocated::Error
      # @messages[:unallocated_group] << (json['isbn_13']&.first || json['isbn_10']&.first)
      return
    rescue IsbnGroup::FailedToFindError
      # @messages[:no_group] << (json['isbn_13']&.first || json['isbn_10']&.first)
      return
    end

    if isbn.nil?
      # @messages[:missing_isbns] += 1
      return
    end

    json['publishers'].each do |pub_name|
      next if pub_name.blank?

      publisher = Publisher.create_or_find_by!(name: pub_name)
      pub_ident = PublisherIsbnRegistration.create_or_find_by!(publisher: publisher, ean: isbn[:ean] || '978', group: isbn[:group].group, number: isbn[:publisher])
      PublisherIsbnRegistration.update_counters(pub_ident.id, { open_library_uses: 1 })
    end
  end

end
