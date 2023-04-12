# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pry'
require 'yaml'
require 'deprecations_collector'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :assets do
  desc "Compiles all assets"
  task :compile do
    puts "Compiling assets"
    require "sprockets"
    base_path = 'lib/deprecations_collector/formatters/html'
    assets = Sprockets::Environment.new
    assets.append_path "#{base_path}/assets/javascripts"
    assets.append_path "#{base_path}/assets/stylesheets"
    assets["application.js"].write_to("#{base_path}/public/application.js")
    assets["settings.js"].write_to("#{base_path}/public/settings.js")
    assets["application.css"].write_to("#{base_path}/public/application.css")
  end
end

namespace :deprecations do
  desc "Combines all results into one"
  task :combine, [:matrix_folder, :matrix_filename] do |_t, args|
    matrix_folder = args[:matrix_folder].to_s

    combined_matrix = Dir.entries(matrix_folder).select { |f| !f.start_with?('.') }.inject({}) do |temp_matrix, file_name|
      matrix = YAML.load_file("#{matrix_folder}/#{file_name}")

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

    DeprecationsCollector::Main.output_path = args[:matrix_folder]
    DeprecationsCollector::Main.save_results(combined_matrix, file_name: args[:matrix_filename])
  end

  desc "Format"
  task :format, [:folder, :matrix_filename] do |_t, args|
    folder = args[:folder]
    matrix = YAML.load_file("#{folder}/#{args[:matrix_filename]}")

    DeprecationsCollector::Main.output_path = args[:folder]
    DeprecationsCollector::Formatters::HTML::Formatter.new.format(matrix)
  end
end
