class Importers::Books::Base < Importers::Base
  def import_object data
    # {
    #   OpenLibrary::WorkWorker => @work,
    #   OpenLibrary::EditionWorker => @edition,
    # }.compact.each do |worker_klass, record|
    #   worker_klass.perform_async(record.id) if record.fetch_open_library?
    #   # worker_klass.new.perform(record.id) if record.fetch_open_library?
    # end

    # {
    #   IsbnDb::EditionWorker => @edition,
    # }.compact.each do |worker_klass, record|
    #   worker_klass.perform_async(record.id) if record.fetch_isbn_db?
    #   # worker_klass.new.perform(record.id) if record.fetch_isbn_db?
    # end
  end
end