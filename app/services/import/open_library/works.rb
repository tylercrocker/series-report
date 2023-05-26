class Import::OpenLibrary::Works < Import::OpenLibrary
  FILE_NAME_SECTION = 'works'.freeze
  OBJECT_CLASS = Work::Book
  NAME_FIELD = 'title'.freeze

  def initialize file_path: '/Users/Tyler/Downloads/series-report/ol_dump_works_latest.txt', sub_file: false
    super(file_path: file_path, sub_file: sub_file)
  end

  # At this point we have an already existing record.
  # https://openlibrary.org/type/work
  # title of type /type/string
  # subtitle of type /type/string
  #+ authors[] of type /type/author_role
  # translated_titles[] of type /type/translated_string
  # subjects[] of type /type/string
  # subject_places[] of type /type/string
  # subject_times[] of type /type/string
  # subject_people[] of type /type/string
  # description of type /type/text
  #+ dewey_number[] of type /type/string
  #+ lc_classifications[] of type /type/string
  # first_sentence of type /type/text
  # original_languages[] of type /type/language -- this is so infrequently filled out it's useless
  # other_titles[] of type /type/string
  # first_publish_date of type /type/string
  # links[] of type /type/link
  # notes of type /type/text -- this appears to never be filled out
  # cover_edition of type /type/edition
  # covers[] of type /type/int
  def update_record work, json, last_modified
    # TODO : I need to ensure I can validate these first, they DO come as an array and can have multiple
    # https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/080Analytics/080Shared_Dimensions/040LC_Classifications
    # work.add_identifier!(Identifier::LcClassifications, json['lc_classifications'].first)
    # work.add_identifier!(Identifier::DeweyDecimalNumber, json['dewey_number'].first)

    work.title = json['title'].squeeze(' ').strip
    work.subtitle = json['subtitle']&.squeeze(' ')&.strip
    work.ol_cover_ids = json['covers']
    work.ol_cover_edition_id = json['cover_edition']['key'] unless json['cover_edition'].nil?

    [json['translated_titles'], json['other_titles']].flatten.compact.each do |alt_title|
      next if alt_title.blank?

      fixed_alt_title = (alt_title.is_a?(Hash) ? alt_title['text'] : alt_title).squeeze(' ').strip
      AlternateName.find_or_create_by(nameable: work, name: fixed_alt_title) unless fixed_alt_title == work.title
    end

    work.description = json['description'].is_a?(Hash) ? json['description']['value'] : json['description']
    work.first_sentence = json['first_sentence'].is_a?(Hash) ? json['first_sentence']['value'] : json['first_sentence']

    add_publish_date(work, json['first_publish_date'])
    add_author_contributions(work, json['authors'])
    add_subjects(work, {
      Subject::OpenLibrary::Subject => json['subjects'].reject{ |s| s.start_with?('nyt:') },
      Subject::OpenLibrary::Nyt => json['subjects'].select{ |s| s.start_with?('nyt:') }.map{ |s| s.sub(/^nyt:/, '') },
      Subject::OpenLibrary::Person => json['subject_people'],
      Subject::OpenLibrary::Place => json['subject_places'],
      Subject::OpenLibrary::Time => json['subject_times']
    })

    work.links = json['links']

    super(work, json, last_modified)
  end
end
