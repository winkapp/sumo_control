require 'pathname'
require 'fileutils'

class SumoControl
  class SourceFile
    attr_reader :path

    def initialize(file_path)
      @path = Pathname.new(file_path)
    end

    def write(source_definition)
      FileUtils.mkdir_p(path.dirname)

      File.open(path, "w+") do |f|
        f.write(source_definition.to_s)
      end
    end
  end
end
