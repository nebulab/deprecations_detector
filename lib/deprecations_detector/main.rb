# frozen_string_literal: true

module DeprecationsDetector
  class Main
    include Singleton

    attr_reader :coverage_matrix, :deprecation_matrix
    attr_accessor :config, :output_path

    def initialize
      @config = {
        file_filter: ->(file_path) { file_of_project?(file_path) }
      }
      @output_path = 'tmp'
    end

    def add(example)
      example_data = slice_attributes(example.metadata, *example_attributes)
      example_data[:example_ref] = example_data.hash

      changes = {}

      select_project_files(deprecation_matrix).each do |file_path, lines|
        lines.each do |line, message|
          # next if example.metadata[:file_path] != file_path.gsub(Dir.pwd, '.') && example.metadata[:line_number] != line

          file_info = { file_path: file_path, line_index: line }
          example = example_data.merge(deprecation_message: message)

          save_changes(changes, example, **file_info)
          save_changes(@coverage_matrix, example, **file_info)
        end
      end

      changes
    end

    def add_deprecation(message, callstack)
      bc = ::ActiveSupport::BacktraceCleaner.new
      bc.add_silencer { |line| !line.match?(Dir.pwd) }
      bc.add_silencer { |line| line.match?('/vendor/bundle/') }
      line_path = bc.clean(callstack).first
      line_path = line_path.to_s

      result = /(\D*)[:](\d*)/.match(line_path)
      return if @deprecation_matrix.nil? || result.nil?

      file_path = result[1] # "#{Dir.pwd}#{result[1]}"

      @deprecation_matrix[file_path] ||= {}
      @deprecation_matrix[file_path][result[2].to_i - 1] = /(.*)\(called.*\)/m.match(message)[1]
    end

    def start
      @coverage_matrix = {}
      @deprecation_matrix = {}
    end

    def save_results(matrix = @coverage_matrix, file_name: ENV['MATRIX_FILENAME'] || 'deprecations_detector.yml')
      matrix = {} if matrix.nil?

      path = File.join(output_path, file_name)
      FileUtils.mkdir_p(output_path)

      File.open(path, 'w') do |f|
        results = matrix.sort.map { |k, v| [k, v.sort.to_h] }.to_h
        f.write results.to_yaml
      end
    end

    class << self
      def method_missing(method, *args, **kwargs, &block)
        if instance.respond_to?(method)
          if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('3')
            instance.send(method, *args, **kwargs, &block)
          else
            instance.send(method, *args, &block)
          end
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        instance.respond_to?(method) || super
      end
    end

    private

    def save_changes(hash, example_data, file_path:, line_index:)
      hash[file_path] ||= {}
      hash[file_path][line_index] ||= []
      hash[file_path][line_index] << example_data
    end

    def slice_attributes(hash, *keys)
      keys.each_with_object({}) { |k, new_hash| new_hash[k] = hash[k] if hash.key?(k) }
    end

    def example_attributes
      %I[full_description file_path line_number]
    end

    def select_project_files(coverage_result)
      coverage_result.select { |file_path, _lines| @config[:file_filter].call(file_path) }
    end

    def file_of_project?(file_path)
      file_path.start_with?(Dir.pwd) && !file_path.start_with?(Dir.pwd + '/spec')
    end
  end
end
