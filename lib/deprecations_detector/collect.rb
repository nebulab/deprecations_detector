# frozen_string_literal: true

module DeprecationsDetector
  class Collect
    def self.call(message = "", callstack = [], deprecation_horizon = nil, gem_name = nil)
      DeprecationsDetector::Main.add_deprecation(message, callstack.map(&:to_s))
    end

    def self.arity
      4
    end
  end
end
