class Importers::Books::Base < Importers::Base
  def import_object _data
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
      # data[:worker].new.perform(data[:record].id)
    end
  end
end
