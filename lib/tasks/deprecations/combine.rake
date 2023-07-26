# frozen_string_literal: true

require 'deprecations_detector'

namespace :deprecations do
  desc "Combines all results into one"
  task :combine, [:matrix_folder, :matrix_filename] do |_t, args|
    matrix_folder = args[:matrix_folder].to_s

    yaml_files = Dir.glob("#{matrix_folder}/**/*.yml").reject { |f| File.directory?(f) }
    combined_matrix = yaml_files.inject({}) do |temp_matrix, file_name|
      begin
        matrix = YAML.load_file(file_name)

        temp_matrix.merge(matrix) do |file, oldval, newval|
          oldval.merge(newval) do |line, old_deprecation, new_deprecation|
            old_deprecation + new_deprecation
          end
        end
      rescue Psych::SyntaxError
        temp_matrix
      rescue Errno::EISDIR
        temp_matrix
      end
    end

    DeprecationsDetector::Main.output_path = args[:matrix_folder]
    DeprecationsDetector::Main.save_results(combined_matrix, file_name: args[:matrix_filename])
  end
end
