require 'deprecations_collector'

RSpec.configure do |config|
  config.before(:suite) do
    DeprecationsCollector::Main.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
    DeprecationsCollector::Main.start
  end

  config.around do |e|
    e.run
    DeprecationsCollector::Main.add(e)
  end

  config.after(:suite) do
    DeprecationsCollector::Main.save_results
    coverage_matrix = DeprecationsCollector::Main.coverage_matrix
    DeprecationsCollector::Formatters::HTML::Formatter.new.format(coverage_matrix)
  end
end
