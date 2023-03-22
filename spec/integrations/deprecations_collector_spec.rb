# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeprecationsCollector do
  let(:deprecations_collector) { DeprecationsCollector::Main }

  around do |e|
    config = deprecations_collector.config.dup

    e.run

    deprecations_collector.config = config
  end

  describe '#add' do
    subject(:described_method) { ->(e) { deprecations_collector.add(e) } }

    let(:example) { -> { expect(SomeClass.new('foo').reverse).to eq 'oof' } }
    let(:start_deprecations_collector) { deprecations_collector.start }

    before do
      start_deprecations_collector
      require_relative '../../spec/faked_project/lib/faked_project.rb'
      example.call
    end

    context 'when faked_project dir path is included' do
      let(:start_deprecations_collector) do
        deprecations_collector.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
        deprecations_collector.start
      end

      it 'fills the coverage_matrix with SomeClass Data' do |e|
        expect(described_method.call(e)).not_to be_empty
        expect(deprecations_collector.coverage_matrix).not_to be_empty
      end
    end
  end

  describe '#start' do
    subject(:described_method) { deprecations_collector.start }

    before do
      deprecations_collector.config[:file_filter] = ->(file_path) { file_path.include? 'faked_project' }
      deprecations_collector.start
      require_relative '../../spec/faked_project/lib/faked_project.rb'
    end

    it 'resets the coverage_matrix' do |e|
      SomeClass.new('foo').reverse
      deprecations_collector.add(e)

      expect(deprecations_collector.coverage_matrix).not_to be_empty

      described_method

      expect(deprecations_collector.coverage_matrix).to be_empty
    end
  end
end
