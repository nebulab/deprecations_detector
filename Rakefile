# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pry'
require 'yaml'

RSpec::Core::RakeTask.new(:spec)

import './lib/tasks/deprecations/combine.rake'
import './lib/tasks/deprecations/format.rake'

task default: :spec

namespace :assets do
  desc "Compiles all assets"
  task :compile do
    puts "Compiling assets"
    require "sprockets"
    base_path = 'lib/deprecations_detector/formatters/html'
    assets = Sprockets::Environment.new
    assets.append_path "#{base_path}/assets/javascripts"
    assets.append_path "#{base_path}/assets/stylesheets"
    assets["application.js"].write_to("#{base_path}/public/application.js")
    assets["settings.js"].write_to("#{base_path}/public/settings.js")
    assets["application.css"].write_to("#{base_path}/public/application.css")
  end
end
