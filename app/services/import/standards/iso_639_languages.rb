class Import::Standards::Iso639Languages < Import::Base
  PROCESS_METHOD = :process_csv

  # https://www.loc.gov/standards/iso639-2/php/code_list.php
  # File was last updated 2017-12-21
  def initialize file_path=File.join(Rails.root, 'lib', 'assets', 'iso_639_languages.csv'), sub_file = false
    super(file_path, sub_file)
  end

  # HEADERS:
  # ISO 639-2 Code,ISO 639-1 Code,English name of Language,French name of Language,German name of Language
  def import_object data
    shared = {
      code_1: data['ISO 639-1 Code'],
      name_en: data['English name of Language'],
      name_fr: data['French name of Language'],
      name_de: data['German name of Language']
    }

    if data['ISO 639-2 Code'].include?("\n")
      code_b, code_t = data['ISO 639-2 Code'].split("\n")

      self.import_object_data(
        code_2: code_b.delete(' (B)'),
        code_2_type: 'bibliographic',
        **shared
      )
      self.import_object_data(
        code_2: code_t.delete(' (T)'),
        code_2_type: 'terminology',
        **shared
      )
    else
      self.import_object_data(code_2: data['ISO 639-2 Code'], **shared)
    end
  end

  def import_object_data code_2:, code_2_type: nil, code_1:, name_en:, name_fr:, name_de:
    { en: name_en, fr: name_fr, de: name_de }.each do |lang, name_set|
      next if name_set.blank?

      name_set.split(';').each do |the_name|
        qualifier_match = the_name.match(/(?<name>.+)(\s\((?<qualifier>[^)]+)\)|,\s(?<qualifier>[^-]+based))/)
        qualifier = qualifier_match.nil? ? nil : qualifier_match[:qualifier]

        parsed_name = qualifier_match.nil? ? the_name.strip : qualifier_match[:name]
        parsed_name = parsed_name.split(', ').reverse.join(' ')

        # These should never get created except for during an import
        # so I don't care about the race condition.
        # create_or_find_by likes to hate me because I'm searching on more than just the unique index
        # The file actually contains some duplicate rows for whatever reason, so it is important to handle this.
        Language.where(
          name_lang: lang,
          name: parsed_name,
          name_qualifier: qualifier,
          iso_639_2: code_2,
          iso_639_2_type: code_2_type,
          iso_639_1: code_1
        ).first_or_create!
      end
    end
  end
end