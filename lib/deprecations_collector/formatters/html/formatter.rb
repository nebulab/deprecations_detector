# frozen_string_literal: true

require "erb"
require "cgi"
require "fileutils"
require "digest/sha1"
require "time"
require "json"

module DeprecationsCollector
  module Formatters
    module HTML
      class Formatter
        def format(result, output_path: DeprecationsCollector::Main.output_path)
          public_r = './public/*'
          Dir[File.join(File.dirname(__FILE__), public_r)].each do |path|
            FileUtils.cp_r(path, asset_output_path(output_path))
          end

          File.open(File.join(output_path, "index.html"), "wb") do |file|
            file.puts template("layout").result(binding)
          end
          puts output_message(result, output_path)
        end

        def output_message(result, output_path)
          "Coverage report generated for #{result.count} files to #{output_path}."
        end

        def asset_output_path(output_path)
          return @asset_output_path if defined?(@asset_output_path) && @asset_output_path

          @asset_output_path = File.join(output_path, "assets", DeprecationsCollector::VERSION)
          FileUtils.mkdir_p(@asset_output_path)
          @asset_output_path
        end

        private

        # Returns the an erb instance for the template of given name
        def template(name)
          ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "#{name}.erb")))
        end

        def assets_path(name)
          File.join("./assets", DeprecationsCollector::VERSION, name)
        end

        # Returns the html for the given source_file
        def formatted_source_file(source_file)
          template("source_file").result(binding)
        rescue Encoding::CompatibilityError => e
          puts "Encoding problems with file #{filename(source_file)}. Simplecov/ERB can't handle non ASCII characters in filenames. Error: #{e.message}."
        end

        def readfile(source_file)
          load_source(filename(source_file))
        end

        def load_source(file_name)
          lines = []
          # The default encoding is UTF-8
          File.open(file_name, "rb:UTF-8") do |file|
            line = file.gets

            # Check for shbang
            if /\A#!/.match?(line)
              lines << line
              line = file.gets
            end
            return lines unless line

            check_magic_comment(file, line)
            lines.concat([line], file.readlines)
          end

          lines
        end

        def check_magic_comment(file, line)
          # Check for encoding magic comment
          # Encoding magic comment must be placed at first line except for shbang
          if (match = /\A#\s*(?:-\*-)?\s*(?:en)?coding:\s*(\S+)\s*(?:-\*-)?\s*\z/.match(line))
            file.set_encoding(match[1], "UTF-8")
          end
        end

        def grouped(files)
          groups = files.group_by do |file_name, lines|
            lines.map do |line, examples|
              examples.map { |example| example[:deprecation_message] }
            end
          end.keys.flatten.uniq

          grouped = {}
          grouped_files = []

          groups.each do |deprecation_message|
            grouped[deprecation_message] = files.select { |source_file, lines| lines.detect { |line, examples| examples.detect { |example| example[:deprecation_message] == deprecation_message } } }
            grouped_files += grouped[deprecation_message].keys
          end
          if !groups.empty? && !(other_files = files.reject { |source_file| grouped_files.include?(source_file) }).empty?
            grouped["Ungrouped"] = other_files
          end

          arr = grouped.map do |deprecation_message, objects|
            [
              deprecation_message,
              -objects.to_a.sum { |file, lines| lines.sum { |line, examples| examples.count } }
            ]
          end.sort_by { |group| group[1] }.to_h.keys[0..6] # filter just the 6 most frequent deprecations

          arr.map { |k| [k, grouped[k]] }.to_h
        end

        # Returns a table containing the given source files
        def formatted_file_list(title, source_files)
          title_id = title.gsub(/^[^a-zA-Z]+/, "").gsub(/[^a-zA-Z0-9\-\_]/, "")
          # Silence a warning by using the following variable to assign to itself:
          # "warning: possibly useless use of a variable in void context"
          # The variable is used by ERB via binding.
          title_id = title_id
          template("file_list").result(binding)
        end

        def coverage_css_class(covered_percent)
          if covered_percent > 90
            "green"
          elsif covered_percent > 80
            "yellow"
          else
            "red"
          end
        end

        def strength_css_class(covered_strength)
          if covered_strength > 1
            "green"
          elsif covered_strength == 1
            "yellow"
          else
            "red"
          end
        end

        def filename(source_file)
          source_file.first.to_s
        end

        # Return a (kind of) unique id for the source file given. Uses SHA1 on path for the id
        def id(source_file)
          Digest::SHA1.hexdigest(filename(source_file))
        end

        def timeago(time)
          "<abbr class=\"timeago\" title=\"#{time.iso8601}\">#{time.iso8601}</abbr>"
        end

        def shortened_filename(source_file)
          filename(source_file).sub(Dir.pwd, '.').gsub(%r{^./}, "")
        end

        def link_to_source_file(source_file)
          %(<a href="##{id source_file}" class="src_link" title="#{shortened_filename source_file}">#{shortened_filename source_file}</a>)
        end
      end
    end
  end
end
