[![Gem Version](https://badge.fury.io/rb/deprecations_collector.svg)](https://badge.fury.io/rb/deprecations_collector)

# DeprecationsCollector

The goal of this component is to collect and list all the deprecation of the project visually.

## Installation

Add `gem 'deprecations_collector', github: 'nebulab/deprecations_collector'` to your application's Gemfile and execute `bundle`.

Put the following code under you specs configuration:

```ruby
require 'deprecations_collector'

RSpec.configure do |config|
  config.before(:suite) do
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
```

## Testing

Execute `bundle exec rspec` on the component root path, specs are based on an internal fake project.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nebulab/deprecations_collector. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

DeprecationsCollector is copyright © 2023 [Nebulab](http://nebulab.it/). It is free software, and may be redistributed under the terms specified in the [license](LICENSE.txt).
Inspired by ReverseCoverage

## About

![Nebulab](http://nebulab.it/assets/images/public/logo.svg)

DeprecationsCollector is funded and maintained by the [Nebulab](http://nebulab.it/) team.

We firmly believe in the power of open-source. [Contact us](http://nebulab.it/contact-us/) if you like our work and you need help with your project design or development.
