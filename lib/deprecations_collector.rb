# frozen_string_literal: true

require 'singleton'
require 'yaml'
require 'active_support'

require_relative 'deprecations_collector/active_support/deprecation_decorator.rb'
require_relative 'deprecations_collector/version'
require_relative 'deprecations_collector/main'
require_relative 'deprecations_collector/formatters/html/formatter'
