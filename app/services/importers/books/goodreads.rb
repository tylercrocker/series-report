# Available keys as of April 2022:
# Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies,Original Purchase Date,Original Purchase Location,Condition,Condition Description,BCID
class Importers::Books::Goodreads < Importers::Books::Base
  NAME_CAPTURE = /(?<name>[^#]+)/
  POSITION_CAPTURE = /,?\s+(?<position>#[\d\.\-]+)/
  PART_CAPTURE = /(?<part>Part\s+[\d]+)/
  CAPTURE_DELIMITER = /[;,]\s+/
  SERIES_TITLE_REGEX = /\(#{NAME_CAPTURE}#{POSITION_CAPTURE}\s*(#{CAPTURE_DELIMITER}#{NAME_CAPTURE}#{POSITION_CAPTURE}\s*|#{CAPTURE_DELIMITER}#{PART_CAPTURE}\s*)*\)$/

  attr_accessor :goodreads_id, :isbn10, :isbn13, :edition, :work, :title, :series

  # TODO : REMOVE
  def initialize file_path='/Users/tyler/Downloads/series-report/goodreads_library_export.csv'
    super(file_path)
  end

  def process
    process_csv
  end

  def import_object data
    puts "\n\n\n\n\n\nSTARTING IMPORT WITH THE FOLLOWING DATA:\n#{data.inspect}\n\n\n\n\n"
    @goodreads_id = data['Book Id']
    # Not sure why Goodreads formats their ISBNs like this...
    @isbn10 = data['ISBN']&.gsub(/^="|"$/, '')
    @isbn13 = data['ISBN13']&.gsub(/^="|"$/, '')

    edition_scope = Edition::Book.by_goodreads_id(@goodreads_id)
    edition_scope = edition_scope.or(Edition::Book.by_isbn10(@isbn10)) unless @isbn10.blank?
    edition_scope = edition_scope.or(Edition::Book.by_isbn13(@isbn13)) unless @isbn13.blank?
    @edition = edition_scope.first
    @work = @edition&.work

    author = find_or_create_author(data)
    title = process_series_from_title(data['Title'].strip.squeeze(' '))

    if @work.nil?
      # If we had no work we need to build that first
      @work = Work::Book.create!(title: title)
      Contribution::Author.create_or_find_by(contributable: @work, person: author)
      
      # If we have more than one record at this point we had a race condition.
      # We should always use the one with the lowest denoted slug and destroy the other one.
      # If the other one was not created by us let's let whoever created it destroy it tho!
      works = Work::Book.joins(:people).where(title: title, people: { id: author.id }).order(:slug).all
      if works.first == @work
        # Once we know we're dealing with the new work record we can add any extra data.
        @work.year_published ||= data['Original Publication Year']
        @work.save!
      else
        @work.destroy!
        @work = works.first
      end
    else
      # Let's verify the data we found makes sense
      raise 'HOW DID THE AUTHOR NOT MATCH?' if @work.people.where(id: author.id).blank?
    end

    # Now we can build out the edition
    # TODO: figure out how to deal with this race condition...
    @edition ||= Edition::Book.where(work: @work, title: title).first_or_initialize
    @edition.year_published ||= data['Year Published']
    @edition.binding_type ||= Edition::Book.standardize_binding(data['Binding'])
    @edition.num_pages ||= data['Number of Pages'] if data['Number of Pages'].to_i.positive?
    @edition.save!

    @edition.add_identifier!(EditionIdentifier::GoodreadsId, @goodreads_id)
    @edition.add_identifier!(EditionIdentifier::Isbn10, @isbn10)
    @edition.add_identifier!(EditionIdentifier::Isbn13, @isbn13)

    unless @edition.contributions.where(person: author).present?
      Contribution::Author.create_or_find_by(contributable: @edition, person: author)
    end

    # @additional_authors = []
    # data['Additional Authors']&.split(',')

    @series.each do |series_name, info|
      # This has a SLIGHT race condition issue, we should be able to ignore it
      collection = Collection.find_or_create_by_scope!(Collection::Series.by_creator_or_contributor(author), series_name)
      Contribution::Creator.create_or_find_by(contributable: collection, person: author)
      collection.add_item!(@work, position: info[:position], position_extra: info[:position_extra])

      EditRequest::SeriesMerge.check_for_mergers(collection)
    end
  end

  def find_or_create_author data
    # Generally trusting that both versions of the author's name will be there
    # It seems to be from my sample so far
    author_fl = data['Author'].strip.squeeze(' ')
    author_lf = data['Author l-f'].strip.squeeze(' ')

    # First let's just look for an exact match
    author = Person.with_book_roles.where(name: author_fl, name_last_first: author_lf).first
    return author unless author.nil?

    # If we didn't have an exact match let's try and do some more fuzzy-type matching
    people = Person.with_book_roles.by_names([author_fl, author_lf]).to_a.uniq
    case people.length
    when 0
      # This has a VERY minor race condition issue, we should be able to ignore it
      Person.with_book_roles.where(name: author_fl, name_last_first: author_lf).first_or_create
    when 1
      people.first
    else
      raise 'WHY DID WE HAVE MULTIPLE AUTHOR RECORDS?!'
    end
  end

  def process_series_from_title title
    @series = {}

    series_data = title.scan(SERIES_TITLE_REGEX).flatten.compact
    # If we had no matches then there was no series info
    return title if series_data.empty?

    current_series = nil
    series_data.each do |datum|
      if datum.start_with?('#')
        if datum.include?('-')
          @series[current_series][:position_extra] = datum.sub(/^#/, '')
        else
          @series[current_series][:position] = datum.sub(/^#/, '')
        end
      elsif datum.start_with?('Part ')
        @series[current_series][:position_extra] = datum
      else
        # Regex pulls in the trailing comma/space, so let's get rid of them
        current_series = datum.strip.gsub(/(,\s*|\s+)$/, '')
        @series[current_series] = {}
      end
    end

    title.sub(SERIES_TITLE_REGEX, '').strip
  end
end