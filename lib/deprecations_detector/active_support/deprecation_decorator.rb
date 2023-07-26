# frozen_string_literal: true

module DeprecationsDetector
  module ActiveSupport
    module DeprecationDecorator
      def warn(message = nil, callstack = caller)
        DeprecationsDetector::Main.add_deprecation(message, caller)

        return if DeprecationsDetector::Main.suppress_deprecations

        super(message, callstack)
      end

      ::ActiveSupport::Deprecation.prepend(self)
    end
  end
end
