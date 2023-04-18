module WorksHelper
  def authors_for author_hash
    return 'Unknown' if author_hash.nil?

    if author_hash.keys == ['Author'] && author_hash.values.flatten.size == 1
      # Only one author and it's the primary author, we can do a simple printing of the name
      return author_hash.values.flatten.first.name
    end

    if author_hash['Author']&.size == 1
      # We have a single primary author but we also have other author types, lets put them in a tooltip?
      # TODO -- I haven't written the multi-author import logic yet...
    end
  end
end
