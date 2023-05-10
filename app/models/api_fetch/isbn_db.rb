class ApiFetch::IsbnDb < ApiFetch

  # Just matches anything with parenths or brackets at the end
  # eg: "xyz (..." or "xyz [..."
  PARENTHETICAL_MATCH = /\s*(\(|\[).*/

  def edition_by_isbn isbn13, isbn10
    begin
      ISBNDB_CLIENT.book.find(isbn13)[:book]
    rescue ISBNdb::RequestError => e
      raise e if isbn10.nil?

      ISBNDB_CLIENT.book.find(isbn10)[:book]
    end
  end

  def batch_editions_by_isbn editions

  end

  # We need the whole edition for this one because we need to be able to do some validation
  # Note that this is only really used when we don't have ISBN information for an edition.
  # This should NOT be used to fill out lists of editions for a work!
  def edition_by_title edition
    self.messages = {}

    begin
      params = {
        author: CGI.escape(edition.best_author_for_search.name),
        publisher: edition.publisher.nil? ? nil : CGI.escape(edition.publisher),
        text: CGI.escape(edition.title),
        pageSize: 100
      }

      api_data = ISBNDB_CLIENT.book.search(params)
    rescue ISBNdb::RequestError => e
      self.status = :failure
      self.messages[:failed_from] = :title_search
      self.messages[:error_class] = e.class.name
      self.messages[:reason] = e.detailed_message
      self.save!
      return
    end

    book_data_to_use = nil
    matched_with_missing = []
    far_matches = []
    missed = {}


    api_data[:data].each do |book_data|
      title_match = TitleProcessor.rough_match?(book_data[:title], edition.title)
      next unless title_match[:matched]

      matches = 0
      possible_matches = 0
      missing = []

      {
        pages: { book_data[:pages].to_i => edition.num_pages },
        date_published: { book_data[:date_published].to_i => edition.year_published },
        binding: {
          Edition::Book.standardize_binding(book_data[:binding]) => edition.binding_type
        },
        publisher: {
          book_data[:publisher] => edition.publisher
        }
      }.each do |field, data|
        their_data = data.keys.first
        our_data = data.values.first
        if their_data == our_data
          matches += 1
        elsif their_data != 0 && their_data.present? && our_data.blank?
          # 0.present? is true :(
          possible_matches += 1
        else
          missing << field
        end
      end

      if matches == 4
        book_data_to_use = book_data
      elsif (matches + possible_matches) == 4
        matched_with_missing << book_data
      elsif (missing - [:pages, :publisher]).size.zero?
        far_matches << book_data
      else
        missed[missing] ||= []
        missed[missing] << book_data
      end
    end

    # In this case we had an exact match, yay!
    return book_data_to_use unless book_data_to_use.nil?

    self.status = :failure
    self.messages[:reason] = :no_exact_match
    self.messages[:possible_matches] = matched_with_missing.size
    self.save!

    nil
  end

  def update_edition_from_api_data! edition, api_data
    return if edition.nil? || api_data.blank?

    # First add identifiers, this will help for reprocessing data if we need to
    edition.add_identifier!(EditionIdentifier::Isbn10, api_data[:isbn10]) if api_data[:isbn10]
    edition.add_identifier!(EditionIdentifier::Isbn13, api_data[:isbn13]) if api_data[:isbn13]

    # Always resetting this, it only saves if we get through the whole process anyway
    self.messages = { 'discrepancies' => {} }

    # title, series = TitleProcessor.series_data_from_book_title

    # TODO : I feel like I should do something with their "title_long" field, but I need to do research

    {
      binding_type: :binding,
      year_published: :date_published,
      msrp: :msrp,
      dimensions: :dimensions,
      language: :language,
      num_pages: :pages,
      # edition: :edition,
      isbndb_image_url: :image,
      publisher: :publisher
    }.each do |our_key, their_key|
      if edition.send(our_key).blank?
        edition.send("#{our_key}=", api_data[their_key])
      elsif api_data[their_key].present? && edition.send(our_key) != api_data[their_key]
        self.messages['discrepancies'][our_key] = api_data[their_key]
      else
        # We don't need to actually update it if it was already the same!
      end
    end

    edition.save!

    if self.messages['discrepancies'].present?
      self.status = :success_with_discrepancies
    else
      self.messages = {}
      self.status = :success
    end
    self.save!
  end

end
