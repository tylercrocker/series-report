class EditRequest::SeriesMerge < EditRequest

  def self.check_for_mergers collection
    similar = collection.find_similar
    return if similar.empty?

    # We had direct series collisions, let's create a merge request if we don't already have one
    requests = collection.edit_requests.where(type: self.name).to_a
    statuses = requests.map(&:status).uniq

    # if we had processing/approved/denied entries then we should just be skipping over this
    # if we have a processing request let's let THAT get handled first... we should maybe queue something to get handled after the fact?
    # if we had an approved I don't even understand what happened, those should get destroyed with their collections as they're merged.
    # if we had a denied then we already decided they shouldn't be merged, we don't want the system to be automatically creating merge requests in this case, a user can make the request manually if they want tho!
    return if (statuses & ['processing', 'approved', 'denied']).present?

    update_similar = false
    similar_ids = (similar.map(&:id) + [collection.id]).sort
    if statuses.empty? || statuses == ['ignored']
      self.create_for_similar!(collection, similar_ids, requests.map(&:id))
      update_similar = true
    else
      # TODO : multiple waiting requests should really get merged into a single...
      # we have to take into account requests made by users though, so let's handle that later
      # for now the importer should never be creating multiple waiting records, so we shouldn't have to worry about that!
      ignored = requests.select{ |request| request.ignored? }.map(&:id)
      requests.select{ |request| request.waiting? }.each do |request|
        request.request[:merge_options] = similar_ids
        request.request[:ignored_requests] = ignored
        request.save!
      end
      update_similar = true
    end

    return unless update_similar

    similar.each do |similar_collection|
      similar_collection.edit_requests.where(type: self.name, status: 'waiting').each do |similar_request|
        similar_request.request[:merge_options] = similar_ids
        similar_request.save!
      end
    end
  end

  def self.create_for_similar! collection, similar_ids, ignored_ids
    self.create!(
      editable: collection,
      source: 'system',
      status: 'waiting',
      request: {
        reason: 'matching name',
        merge_options: similar_ids,
        ignored_requests: ignored_ids
      }
    )
  end

  def format_for_api editable_class
    opts = editable_class.where(id: self.request['merge_options'])

    self.request['merge_options'] = opts.inject([]) do |h, collection|
      # These are both kinda obnoxious N+1 queries...
      # I'd really like to figure out a better way to deal with them but they only really get called for small amounts of data so it's probably just not a big deal and the complexity of writing the code would make it difficult to read and maintain.
      people = collection.people.select(:id, :slug, :name, 'contributions.type AS series_contribution')

      h << {
        slug: collection.slug,
        title: collection.title,
        people: people.inject([]) do |ih, person|
          ih << {
            slug: person.slug,
            name: person.name,
            contribution: person.series_contribution,
            work_slugs: person.series_contribution_work_slugs(collection)
          }
          ih
        end
      }
      h
    end
  end

  def process_edit_request! edit_request_data
    series = Collection::Series.where(slug: edit_request_data.keys).order(:slug).to_a
    top_level = series.shift

    # We still have to update contribution records for the top level, so let's still call the merge function for it!
    top_level.merge!(top_level, contributions: edit_request_data[top_level.slug])

    while series.length.positive?
      series_to_merge = series.shift
      top_level.merge!(series_to_merge, contributions: edit_request_data[series_to_merge.slug])
    end

    self.status = :approved
    self.save!
  end
end
