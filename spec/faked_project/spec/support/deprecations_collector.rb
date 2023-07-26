require 'deprecations_collector'

RSpec.configure do |config|
  config.before(:suite) do
    DeprecationsDetector::Main.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
    DeprecationsDetector::Main.start
  end

  config.around do |e|
    e.run
    DeprecationsDetector::Main.add(e)
  end

  config.after(:suite) do
    DeprecationsDetector::Main.save_results
    coverage_matrix = DeprecationsDetector::Main.coverage_matrix
    DeprecationsDetector::Formatters::HTML::Formatter.new.format(coverage_matrix)
  end
end
