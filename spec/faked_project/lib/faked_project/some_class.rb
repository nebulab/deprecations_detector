# frozen_string_literal: true

class SomeClass
  attr_reader :label
  attr_accessor :some_attr

  def initialize(label)
    @label = label
  end

  def reverse
    deprecated_reverse
  end

  def deprecated_reverse
    deprecator = ActiveSupport::Deprecation.new
    deprecator.behavior = DeprecationsDetector::Collect
    deprecator.warn('My Deprecation')

    label.reverse
  end

  def downcase
    label.downcase
  end

  def compare_with(item)
    raise 'Item does not match label' unless item == label

    true
  rescue StandardError
    false
  end

  private

  def uncovered
    'private method'
  end
end
