class Importers::Base
  def initialize the_file_path
    @file_path = the_file_path if the_file_path.start_with?('/')
    @file_path ||= File.join(Rails.root, 'storage', the_file_path)

    raise Errors::FileReadError, @file_path unless File.exist?(@file_path)
  end

  def process
    raise 'Override this method, specify `process_csv` vs `process_json`'
  end

  def import_object data
    raise 'Override this method'
  end

  def process_csv
    CSV.foreach(@file_path, headers: true) do |csv_row|
      import_object(csv_row)
    end

    nil # Don't return anything for cleaner console use
  end

  def process_json
    # TODO : probably should better handle JSON parse errors
    data = JSON.parse(File.read(@file_path))
    if data.is_a?(Array)
      data.each do |json_record|
        import_object(json_record)
      end
    else
      data.values.each do |json_record|
        import_object(json_record)
      end
    end

    nil # Don't return anything for cleaner console use
  end
end
