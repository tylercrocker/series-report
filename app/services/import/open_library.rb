class Import::OpenLibrary < Import::Base
  PROCESS_METHOD = :process_tsv
  BASE_FOLDER = File.join(Rails.root, 'storage', 'import')
  MONTH_YEAR_REGEX = /^(january|february|march|april|may|june|july|august|september|october|november|december)\s\d+$/i

  # https://openlibrary.org/developers/dumps
  def initialize file_path: nil, sub_file: false
    if file_path.nil?
      # ensure directory
      FileUtils.mkdir_p(BASE_FOLDER)

      `wget https://openlibrary.org/data/ol_dump_#{self.class::FILE_NAME_SECTION}_latest.txt.gz -P #{BASE_FOLDER}`

      zip_file_path = File.join(BASE_FOLDER, 'ol_dump_' + self.class::FILE_NAME_SECTION + '*.txt.gz')
      unzipped_file_path = File.join(BASE_FOLDER, 'ol_dump_' + self.class::FILE_NAME_SECTION + '_latest.txt')

      `gzip -d -c #{zip_file_path} > #{unzipped_file_path}`

      File.delete(zip_file_path)

      super(file_path: unzipped_file_path, sub_file: sub_file)
    else
      super(file_path: file_path, sub_file: sub_file)
    end
  end

  def validate_object json
    return if json.exclude?("\"#{self.class::NAME_FIELD}\":")

    json
  end

  def update_record record, _json, last_modified
    record.save!
    record.open_library_id.source_last_modified = DateTime.parse(last_modified)
    record.open_library_id.save!
  end

  # Array of the following
  # type - type of record (/type/edition, /type/work etc.)
  # key - unique key of the record. (/books/OL1M etc.)
  # revision - revision number of the record
  # last_modified - last modified timestamp
  # JSON - the complete record in JSON format
  def import_object values
    @creation_params = {}
    _type, key, _revision, last_modified, json = values
    json = self.validate_object(json)
    return if json.nil?

    record = self.class::OBJECT_CLASS.by_identifier(Identifier::OpenLibraryId, key).first
    if record.nil?
      json = JSON.parse(json) unless json.is_a?(Hash)
      # TODO : Should also do some lookup on title and author or something...
      self.import_new_record(key, json, last_modified)
    elsif record.open_library_id.source_last_modified.nil? || record.open_library_id.source_last_modified < DateTime.parse(last_modified)
      json = JSON.parse(json) unless json.is_a?(Hash)
      self.update_record(record, json, last_modified)
    end
  end

  def import_new_record key, json, last_modified
    return if json[self.class::NAME_FIELD].blank?

    # TODO : I should also look if there's a record with a matching name WITHOUT an OL identifier

    @creation_params = @creation_params.merge({
      self.class::NAME_FIELD.to_sym => json[self.class::NAME_FIELD].squeeze(' ').strip
    })
    record = self.class::OBJECT_CLASS.create_with_slug!(**@creation_params)
    return if record.nil?

    record.add_identifier!(Identifier::OpenLibraryId, key)

    # Handle race conditions...
    records = self.class::OBJECT_CLASS.by_identifier(Identifier::OpenLibraryId, key).order(:slug)
    unless records.first.id == record.id
      record.destroy!
      record = records.first
    end

    self.update_record(record, json, last_modified)
  end

  def add_publish_date record, publish_date
    return if publish_date.blank?

    if publish_date.to_i.to_s == publish_date
      record.year_published = publish_date.to_i
    elsif publish_date.match?(MONTH_YEAR_REGEX)
      date = Date.parse(publish_date)
      record.year_published = date.year
      record.month_published = date.month
    else
      begin
        date = Date.parse(publish_date)
        date = Date.parse("#{date.year.to_s.first(4)}-#{date.month}-#{date.day}") if date.year.to_s.length > 4

        if publish_date.split(' ').size == 2
          record.year_published = date.year
          record.month_published = date.month
        else
          record.published_on = date
          record.year_published = date.year
          record.month_published = date.month
        end
      rescue Date::Error, ArgumentError
        # just throwing the data away for now
      end
    end
  end

  def add_author_contributions record, authors
    return if authors.nil?

    author_keys = Set.new
    authors.each do |author|
      author_keys << author.dig('author', 'key') || author['key']
    end

    author_keys = author_keys.compact
    return if author_keys.empty?

    people = Person.by_open_library_id(author_keys).to_a

    if people.size > 1
      people.each do |author|
        Contribution::CoAuthor.create_or_find_by(contributable: record, person: author)
      end
    else
      Contribution::Author.create_or_find_by(contributable: record, person: people.first)
    end
  end

  def add_subjects record, class_subjects_pairs
    subjects = Set.new

    class_subjects_pairs&.each do |subject_class, subject_list|
      next if subject_list.nil?

      subject_list.each do |subject|
        next if subject.blank?

        subjects << subject_class.create_or_find_by(name: subject.squeeze(' ').strip.sub(/\.$/, ''))
      end
    end

    record.subjects = subjects
  end

  def add_languages record, languages
    return if languages.nil?

    languages.each do |language|
      iso_639_2 = language['key'].delete('/languages/')
      next if iso_639_2.blank?

      LanguageableLanguage.create_record!(record, iso_639_2)
    end
  end
end