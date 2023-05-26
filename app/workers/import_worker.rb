# Asynchronous import worker, references the "process_set" function from Import::Base with the lines to process
class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'imports'

  def perform import_class, file_path
    import_class.constantize.new(file_path: file_path, sub_file: true).process(delete_file: true)
  end
end