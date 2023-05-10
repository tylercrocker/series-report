# Abstract sidekiq specifics away from workers
class IsbnDb::BaseWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'isbn_db'

  def perform *_args
    raise 'OVERRIDE THIS'
  end
end