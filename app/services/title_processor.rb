class TitleProcessor
  # Pulls series information from a Goodreads title
  NAME_CAPTURE = /(?<name>[^#]+)/
  POSITION_CAPTURE = /,?\s+(?<position>#[\d\.\-]+)/
  PART_CAPTURE = /(?<part>Part\s+[\d]+)/
  CAPTURE_DELIMITER = /[;,]\s+/
  SERIES_TITLE_REGEX = /\(#{NAME_CAPTURE}#{POSITION_CAPTURE}\s*(#{CAPTURE_DELIMITER}#{NAME_CAPTURE}#{POSITION_CAPTURE}\s*|#{CAPTURE_DELIMITER}#{PART_CAPTURE}\s*)*\)$/

  # Just matches anything with parenths or brackets at the end
  # eg: "xyz (..." or "xyz [..."
  PARENTHETICAL_MATCH = /\s*(\(|\[).*/

  def self.rough_match? orig_title_a, orig_title_b
    return {
      matched: true,
      reason: :exact
    } if orig_title_a == orig_title_b

    title_a = orig_title_a.gsub('&', 'and')
    title_b = orig_title_b.gsub('&', 'and')
    return {
      matched: true,
      reason: :ampersands
    } if orig_title_a == orig_title_b
      
    title_a = title_a.downcase
    title_b = title_b.downcase
    return {
      matched: true,
      reason: :case_insensitive
    } if title_a == title_b

    title_b = title_b.sub(PARENTHETICAL_MATCH, '')
    return {
      matched: true,
      reason: :started_with
    } if title_a.start_with?(title_b)
    return {
      matched: true,
      reason: :ended_with
    } if title_a.end_with?(title_b)

    title_a = title_a.sub(PARENTHETICAL_MATCH, '')
    return {
      matched: true,
      reason: :without_trailing_parenths
    } if title_a == title_b
    return {
      matched: true,
      reason: :started_with_without_trailing_parenths
    } if title_a.start_with?(title_b)

    { matched: false }
  end

  def self.series_data_from_book_title title
    series = {}

    series_data = title.scan(SERIES_TITLE_REGEX).flatten.compact
    # If we had no matches then there was no series info
    return [title, series] if series_data.empty?

    current_series = nil
    series_data.each do |datum|
      if datum.start_with?('#')
        if datum.include?('-')
          series[current_series][:position_extra] = datum.sub(/^#/, '')
        else
          series[current_series][:position] = datum.sub(/^#/, '')
        end
      elsif datum.start_with?('Part ')
        series[current_series][:position_extra] = datum
      else
        # Regex pulls in the trailing comma/space, so let's get rid of them
        current_series = datum.strip.gsub(/(,\s*|\s+)$/, '')
        series[current_series] = {}
      end
    end

    [title.sub(SERIES_TITLE_REGEX, '').strip, series]
  end

end
