# Available keys as of April 2022:
# Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies,Original Purchase Date,Original Purchase Location,Condition,Condition Description,BCID
class Import::Goodreads < Import::Base
  PROCESS_METHOD = :process_csv

  attr_accessor :goodreads_id, :isbn10, :isbn13, :edition, :work, :title, :series

  # TODO : REMOVE
  def initialize file_path: '/Users/tyler/Downloads/series-report/goodreads_library_export.csv', sub_file: true
    super(file_path: file_path, sub_file: sub_file)
  end

  def process delete_file: false
    super(delete_file: delete_file)
  end

  def import_object data
    self.existing_edition_by_ids(data)

    author = find_or_create_main_author(data)
    title, @series = TitleProcessor.series_data_from_book_title(data['Title'].strip.squeeze(' '))
    self.ensure_work_record!(author, title, data)
    self.ensure_edition_record!(title, data)
    self.update_edition_record!(author, data)

    # Finally we can start attempting to build out some series information based on what we pulled off while parsing the title earlier.
    @series.each do |series_name, info|
      # This has a SLIGHT race condition issue, we should be able to ignore it
      collection = Collection.find_or_create_by_scope!(Collection::Series.by_creator_or_contributor(author), series_name)
      Contribution::Creator.create_or_find_by(contributable: collection, person: author)
      collection.add_item!(@work, position: info[:position], position_extra: info[:position_extra])

      EditRequest::SeriesMerge.check_for_mergers(collection)
    end

    {
      ApiFetch::IsbnDb => {
        record: @edition,
        require_none: [@isbn10, @isbn13],
        worker: IsbnDb::EditionTitleWorker
      },
    }.compact.each do |fetch_class, data|
      next if data[:record].nil? || data[:require_none].compact.present?

      fetch_record = fetch_class.where(fetchable: data[:record]).first
      next unless fetch_record&.last_fetched_at.nil? || fetch_record.last_fetched_at < 6.months.ago

      data[:worker].perform_async(data[:record].id)
    end
  end

  def find_or_create_main_author data
    # Generally trusting that both versions of the author's name will be there
    # It seems to be from my sample so far
    author_fl = data['Author'].strip.squeeze(' ')
    # author_lf = data['Author l-f'].strip.squeeze(' ')

    # First let's just look for an exact match
    author = Person.with_book_roles.where(name: author_fl).first
    return author unless author.nil?

    # If we didn't have an exact match let's try and do some more fuzzy-type matching
    people = Person.with_book_roles.by_names(author_fl).to_a.uniq
    case people.length
    when 0
      # This has a VERY minor race condition issue, we should be able to ignore it
      Person.with_book_roles.where(name: author_fl).first_or_create
    when 1
      people.first
    else
      raise 'WHY DID WE HAVE MULTIPLE AUTHOR RECORDS?!'
    end
  end

  def build_edition_scope
    edition_scope = Edition::Book.by_goodreads_id(@goodreads_id)
    edition_scope = edition_scope.or(Edition::Book.by_isbn10(@isbn10)) unless @isbn10.blank?
    edition_scope = edition_scope.or(Edition::Book.by_isbn13(@isbn13)) unless @isbn13.blank?
    edition_scope
  end

  # This is re-usable for checking race conditions by passing data as nil.
  # 
  def existing_edition_by_ids data
    @goodreads_id = data['Book Id']
    # Not sure why Goodreads formats their ISBNs like this...
    @isbn10 = data['ISBN']&.gsub(/^="|"$/, '')
    @isbn13 = data['ISBN13']&.gsub(/^="|"$/, '')

    @edition = build_edition_scope.first
  end

  def ensure_work_record!(author, title, data)
    @work = @edition&.work
    unless @work.nil?
      raise 'HOW DID THE AUTHOR NOT MATCH?' if @work.people.where(id: author.id).blank?

      return # Everything looks good, we can just use the existing record :)
    end

    # First see if we already have a work with the title and author.
    @work = Work::Book.joins(:people).where(title: title, people: { id: author.id }).order(:slug).first
    return unless @work.nil?

    # If we had no work we need to just build one first
    # this can cause a race condition, we'll handle that in a sec!
    @work = Work::Book.create!(title: title)
    Contribution::Author.create_or_find_by(contributable: @work, person: author)

    # If we have more than one record at this point we had a race condition.
    # We should always use the one with the lowest denoted slug and destroy the other one.
    # If the other one was not created by us let's let whoever created it destroy it tho!
    works = Work::Book.joins(:people).where(title: title, people: { id: author.id }).order(:slug).all
    unless works.first.id == @work.id
      @work.destroy!
      @work = works.first
    end

    # Once we know we're dealing with the final work record we can add any extra data.
    @work.year_published ||= data['Original Publication Year']
    @work.save!
  end

  def ensure_edition_record! title, data
    return unless @edition.nil?

    # This can have a pretty strong race condition, we'll handle it in a sec
    @edition = Edition::Book.without_goodreads_id.where(work: @work, title: title).first_or_initialize
    # We currently need these due to their being part of the slug...
    @edition.year_published ||= data['Year Published']
    @edition.binding_type ||= data['Binding']
    @edition.save!
    @edition.add_identifier!(Identifier::GoodreadsId, @goodreads_id)

    editions = build_edition_scope.order(:id).all
    # If the first edition was ours then we can safely use it,
    # otherwise let's destroy what we made and use the first one found (by slug),
    # any other portion of the race condition will be handled by whoever created after us
    unless editions.first.id == @edition.id
      @edition.destroy!
      @edition = editions.first
    end
  end

  def update_edition_record! author, data
    @edition.add_identifier!(Identifier::GoodreadsId, @goodreads_id)
    @isbn10 = @edition.add_identifier!(Identifier::Isbn10, @isbn10)
    @isbn13 = @edition.add_identifier!(Identifier::Isbn13, @isbn13)

    # TODO : we should make an API fetch record that adds the conflict notations...
    # for now I'm just doing ||= for everything though since Goodreads exports can just be out of date.
    # TODO : publisher data should eventually get split to a separate table
    @edition.publisher ||= data['Publisher']
    @edition.year_published ||= data['Year Published']
    @edition.binding_type ||= data['Binding']
    @edition.num_pages ||= data['Number of Pages'] if data['Number of Pages'].to_i.positive?
    @edition.save!

    # Now let's start handling author information for the edition...
    # this can get complicated and some of it will be guesswork since Goodreads gives us a singular "Author" and a comma delimited set of "Additional Authors"
    # Note that some of the author data might carry onto the work and some may not since it would be considered edition specific (illustrators, for example)
    unless @edition.contributions.where(person: author).present?
      Contribution::Author.create_or_find_by(contributable: @edition, person: author)
    end

    # @additional_authors = []
    # data['Additional Authors']&.split(',')
  end
end