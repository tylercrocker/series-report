class Import::Base
  class FileReadError < StandardError;end

  def initialize file_path:, sub_file: false
    @file_path = file_path if file_path.start_with?('/')
    @file_path ||= File.join(Rails.root, 'storage', file_path)
    @sub_file = sub_file

    raise FileReadError, @file_path unless File.exist?(@file_path)
  end

  def process delete_file: false
    if @sub_file || [:process_json, :process_xml].include?(self.class::PROCESS_METHOD)
      self.send(self.class::PROCESS_METHOD)
      File.delete(@file_path) if delete_file
      return
    end

    puts "Splitting file..."

    # Make sure we have our directory
    dir_path = File.join(Rails.root, 'storage', self.class.name.underscore)
    FileUtils.mkdir_p(dir_path)

    current_file = nil
    last_idx = nil
    File.open(@file_path, 'r').each_line.with_index do |line, idx|
      if (idx % 100).zero?
        puts "Splitting on line #{format_number(idx)}"
        # Start the worker for the last file if we had one
        ImportWorker.perform_async(self.class.name, current_file.path) unless current_file.nil?
        current_file&.close
        current_file = File.open(File.join(dir_path, "row_#{idx}.txt"), 'a')
      end

      current_file << line
      last_idx = idx
    end
    current_file.close
    File.delete(@file_path) if delete_file

    # Start the last worker since the system will always append the last set of lines but not start it
    ImportWorker.perform_async(self.class.name, current_file.path)

    puts "File split, all workers queued."
  end

  def import_object _data
    raise 'Override this method'
  end

  def process_csv
    CSV.foreach(@file_path, headers: true) do |csv_row|
      self.import_object(csv_row)
    end
  end

  def process_tsv
    File.open(@file_path, 'r').each_line do |t|
      self.import_object(t.split("\t"))
    end
  end

  def process_json
    # TODO : probably should better handle JSON parse errors
    data = JSON.parse(File.read(@file_path))
    if data.is_a?(Array)
      data.each do |json_record|
        self.import_object(json_record)
      end
    else
      data.values.each do |json_record|
        self.import_object(json_record)
      end
    end
  end

  def process_xml
    xml = Nokogiri::XML(File.open(@file_path))

    self.import_object(xml)
  end

  protected

  def format_number number
    num_groups = number.to_s.chars.to_a.reverse.each_slice(3)
    num_groups.map(&:join).join(',').reverse
  end

  def format_time seconds
    hours = (seconds / 60 / 24).to_i
    seconds = seconds - hours * 60 * 24
    mins = (seconds / 60).to_i
    seconds = (seconds % 60).to_i
    "#{hours.to_s.rjust(2, '0')}:#{mins.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
  end
end
