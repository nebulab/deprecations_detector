# frozen_string_literal: true

require 'deprecations_detector'

namespace :deprecations do
  desc "Format"
  task :format, [:folder, :matrix_filename] do |_t, args|
    folder = args[:folder]
    matrix = YAML.load_file("#{folder}/#{args[:matrix_filename]}")

    DeprecationsDetector::Main.output_path = args[:folder]
    DeprecationsDetector::Formatters::HTML::Formatter.new.format(matrix)
  end
end
