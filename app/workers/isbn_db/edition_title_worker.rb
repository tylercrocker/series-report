# This should only be used for editions that are missing ISBNs!
# Normally books should be done in batches to reduce overall API qeries.
class IsbnDb::EditionTitleWorker < IsbnDb::BaseWorker
  def perform edition_id
    edition = Edition.where(id: edition_id).preload(:edition_identifiers).first
    return if edition.nil?

    begin
      api_fetch = ApiFetch::IsbnDb.where(fetchable: edition).first_or_create!
    rescue ActiveRecord::RecordNotUnique
      # if this happened we somehow queued two workers, let the first one take it from here
      return
    end

    # There is technically a race condition here... but I'm not super worried about it
    # return if api_fetch.processing?

    api_fetch.status = :processing
    api_fetch.save!

    # identifiers = edition.edition_identifiers.index_by(&:type)
    # isbn13, isbn10 = [
    #   identifiers['EditionIdentifier::Isbn13']&.identifier,
    #   identifiers['EditionIdentifier::Isbn10']&.identifier
    # ]

    begin
      api_edition = api_fetch.edition_by_title(edition)
      return if api_edition.nil?

      api_fetch.update_edition_from_api_data!(edition, api_edition)

      api_fetch.messages = {}
      api_fetch.status = :success
      api_fetch.save!
    rescue StandardError => e
      # Not sure what can happen here... let's record the information to try and debug!
      api_fetch.status = :failure
      api_fetch.messages = {
        error: e.class.to_s,
        message: e.detailed_message,
        backtrace: e.backtrace
      }
      api_fetch.save!
    end
  end
end
