# frozen_string_literal: true

module DeprecationsCollector
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
      coverage_result = Coverage.peek_result
      example_data = slice_attributes(example.metadata, *example_attributes)
      example_data[:example_ref] = example_data.hash
      current_state = select_project_files(coverage_result)
      all_changed_files = changed_lines(@last_state, current_state)

      changes = {}

      all_changed_files.each do |file_path, lines|
        lines.each_with_index do |changed, line_index|
          next if changed.nil? || changed.zero?
          next if @deprecation_matrix.dig(file_path.gsub(Dir.pwd, ''), line_index).nil?

          file_info = { file_path: file_path, line_index: line_index }
          example = example_data.merge(deprecation_message: @deprecation_matrix.dig(file_path.gsub(Dir.pwd, ''), line_index))

          save_changes(changes, example, **file_info)
          save_changes(coverage_matrix, example, **file_info)
        end
      end

      reset_last_state
      changes
    end

    def add_deprecation(message, callstack)
      bc = ::ActiveSupport::BacktraceCleaner.new
      bc.add_filter   { |line| line.to_s.gsub(Dir.pwd, '') }
      callstack = bc.clean(callstack)# [1..-1]
      callstack.map do |line_path|
        line_path = line_path.to_s

        result = /(\D*)[:](\d*)/.match(line_path)
        next if @deprecation_matrix.nil? || result.nil?

        @deprecation_matrix[result[1]] ||= {}
        @deprecation_matrix[result[1]][result[2].to_i - 1] = message
      end
    end

    def reset_last_state(result = Coverage.peek_result)
      @last_state = select_project_files(result)
    end

    def start
      @coverage_matrix = {}
      @deprecation_matrix = {}
      Coverage.start
      reset_last_state
    end

    def save_results(file_name: 'deprecations_collector.yml')
      result_and_stop_coverage
      path = File.join(output_path, file_name)
      FileUtils.mkdir_p(output_path)

      File.open(path, 'w') do |f|
        results = @coverage_matrix.sort.map { |k, v| [k, v.sort.to_h] }.to_h
        f.write results.to_yaml
      end
    end

    def result_and_stop_coverage
      Coverage.result
    end

    class << self
      def method_missing(method, *args, &block)
        instance.respond_to?(method) ? instance.send(method, *args, &block) : super
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

    def changed_lines(prev_state, current_state)
      prev_state.merge(current_state) do |_file_path, prev_line, current_line|
        prev_line.zip(current_line).map { |values| values[0] == values[1] ? nil : (values[1] - values[0]) }
      end
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
