class Import::OpenLibrary::Authors < Import::OpenLibrary
  FILE_NAME_SECTION = 'authors'.freeze
  OBJECT_CLASS = Person
  NAME_FIELD = 'name'.freeze

  def initialize file_path: '/Users/Tyler/Downloads/series-report/ol_dump_authors_latest.txt', sub_file: false
    super(file_path: file_path, sub_file: sub_file)
  end

  # At this point we have an already existing record.
  # https://openlibrary.org/type/author
  # name of type /type/string
  # eastern_order of type /type/boolean -- this is never used
  # personal_name of type /type/string
  # enumeration of type /type/string -- this is never used
  # title of type /type/string -- leaving this for now, it would require some fairly heavy parsing to be useful
  # alternate_names[] of type /type/string
  # uris[] of type /type/string -- this is never used
  # bio of type /type/text
  # location of type /type/string
  # birth_date of type /type/string
  # death_date of type /type/string
  # date of type /type/string
  # wikipedia of type /type/string -- this is supposed to just store the wikipedia link, which can technically also be in links[]
  # links[]
  def update_record person, json, last_modified
    person.name = json['name'].squeeze(' ').strip

    person.bio = json['bio'].is_a?(Hash) ? json['bio']['value'] : json['bio']

    if json['personal_name'].present? && json['personal_name'].squeeze(' ').strip != person.name
      AlternateName.find_or_create_by(nameable: person, name: json['personal_name'].squeeze(' ').strip)
    end

    json['alternate_names']&.each do |alt_name|
      AlternateName.find_or_create_by(nameable: person, name: alt_name.squeeze(' ').strip)
    end

    person.location = json['location']
    person.period_active = json['date']
    ['birth', 'death'].each do |time|
      next if json["#{time}_date"].blank?

      begin
        person.send("#{time}day=", Date.parse(json["#{time}_date"]))
      rescue Date::Error
        if json["#{time}_date"].to_i.to_s == json["#{time}_date"]
          person.send("#{time}_year=", json["#{time}_date"].to_i)
        else
          person.send("#{time}day_estimate=", json["#{time}_date"])
        end
      rescue ArgumentError
        # we can ignore this... there are some limitations to Date.parse and some of the data can just be bonkers
      end
    end

    person.links = json['links']

    if json['wikipedia'].present?
      wiki_link = { 'title' => 'Wikipedia', 'url' => json['wikipedia'] }

      begin
        if person.links.nil?
          # Just a weird nuance with how JsonDatable works...
          person.links = [wiki_link]
        elsif person.links.map(&:values).flatten.exclude?(json['wikipedia'])
          person.links << wiki_link
        end
      rescue JsonDatable::InvalidTypeError
        # This can safely be ignored, it's just cause there was garbage data in the field.
      end
    end

    super(person, json, last_modified)
  end

end
