[![Gem Version](https://badge.fury.io/rb/deprecations_detector.svg)](https://badge.fury.io/rb/deprecations_detector)

# DeprecationsDetector

The goal of this component is to collect and list all the deprecation of the project visually.

## Installation

Add `gem 'deprecations_detector'` to your application's Gemfile and execute `bundle`.

Put the following code under you specs configuration:

```ruby
require 'deprecations_detector'

RSpec.configure do |config|
  config.before(:suite) do
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
```

# Run it on multiple jobs

Sometimes specs are run concurrently on multiple jobs. In order to collect the result on one file this gem provides some
helpful task to combine the result in one single file and then format it.

1. Remove the formatter from the after(:suite) hook
2. Make the task available on your application following the instruction under `Tasks` section.
3. Save the coverage result on the same directory with different name for any job (e.g. tmp/deps/a.yml, tmp/deps/b.yml etc..)
4. Run the task to combine the YAML files `bundle exec rake 'deprecations:combine[tmp/deps/,deprecations_detector.yml]'`
5. Run the task to format the YAML to HTML `bundle exec rake 'deprecations:format[tmp/deps/,deprecations_detector.yml]'`

## Tasks

Add the following lines on your Rakefile to make the DeprecationsDetector tasks available from your application:

```
spec = Gem::Specification.find_by_name 'deprecations_detector'
load "#{spec.gem_dir}/lib/tasks/deprecations/combine.rake"
load "#{spec.gem_dir}/lib/tasks/deprecations/format.rake"
```

## Testing

Execute `bundle exec rspec` on the component root path, specs are based on an internal fake project.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nebulab/deprecations_detector. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

DeprecationsDetector is copyright © 2023 [Nebulab](http://nebulab.it/). It is free software, and may be redistributed under the terms specified in the [license](LICENSE.txt).
Inspired by ReverseCoverage

## About

![Nebulab](http://nebulab.it/assets/images/public/logo.svg)

DeprecationsDetector is funded and maintained by the [Nebulab](http://nebulab.it/) team.

We firmly believe in the power of open-source. [Contact us](http://nebulab.it/contact-us/) if you like our work and you need help with your project design or development.
