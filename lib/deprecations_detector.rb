# frozen_string_literal: true

require 'singleton'
require 'yaml'
require 'active_support'

require_relative 'deprecations_detector/collect'
require_relative 'deprecations_detector/version'
require_relative 'deprecations_detector/main'
require_relative 'deprecations_detector/formatters/html/formatter'
