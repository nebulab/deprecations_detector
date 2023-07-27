# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeprecationsDetector do
  let(:deprecations_detector) { DeprecationsDetector::Main }

  around do |e|
    config = deprecations_detector.config.dup

    e.run

    deprecations_detector.config = config
  end

  describe '#add' do
    subject(:described_method) { ->(e) { deprecations_detector.add(e) } }

    let(:example) { -> { expect(SomeClass.new('foo').reverse).to eq 'oof' } }
    let(:start_deprecations_detector) { deprecations_detector.start }

    before do
      start_deprecations_detector
      require_relative '../../spec/faked_project/lib/faked_project.rb'
      example.call
    end

    context 'when faked_project dir path is included' do
      let(:start_deprecations_detector) do
        deprecations_detector.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
        deprecations_detector.start
      end

      it 'fills the coverage_matrix with SomeClass Data' do |e|
        expect(described_method.call(e)).not_to be_empty
        expect(deprecations_detector.coverage_matrix).not_to be_empty
      end
    end
  end

  describe '#start' do
    subject(:described_method) { deprecations_detector.start }

    before do
      deprecations_detector.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
      deprecations_detector.start
      require_relative '../../spec/faked_project/lib/faked_project.rb'
    end

    it 'resets the coverage_matrix' do |e|
      SomeClass.new('foo').reverse
      deprecations_detector.add(e)

      expect(deprecations_detector.coverage_matrix).not_to be_empty

      described_method

      expect(deprecations_detector.coverage_matrix).to be_empty
    end
  end
end
