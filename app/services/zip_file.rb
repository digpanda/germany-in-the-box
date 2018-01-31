require 'rubygems'
require 'zip'

class ZipFile
  attr_reader :input_dir, :output_file

  # Initialize with the input_dir to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  def perform
    # Dir["#{TEMPORARY_DIRECTORY}*"]
    Zip::File.open(output_file, Zip::File::CREATE) do |zip|
      Dir[File.join(input_dir, '*')].each do |file|
        zipfile.add(file.sub(input_dir, ''), file)
      end
    end
  end

end
