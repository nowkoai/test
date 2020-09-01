# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::GeoHelper do
  describe '.current_node_human_status' do
    where(:primary, :secondary, :result) do
      [
        [true, false, s_('Geo|primary')],
        [false, true, s_('Geo|secondary')],
        [false, false, s_('Geo|misconfigured')]
      ]
    end

    with_them do
      it 'returns correct results' do
        allow(::Gitlab::Geo).to receive(:primary?).and_return(primary)
        allow(::Gitlab::Geo).to receive(:secondary?).and_return(secondary)

        expect(described_class.current_node_human_status).to eq result
      end
    end
  end

  describe 'replicable_types' do
    subject(:names) { helper.replicable_types.map { |t| t[:name_plural] } }

    it 'includes legacy types' do
      expected_names = %w(
        repositories
        wikis
        lfs_objects
        attachments
        job_artifacts
        container_repositories
        design_repositories
      )

      expect(names).to include(*expected_names)
    end

    it 'includes replicator types' do
      expected_names = helper.enabled_replicator_classes.map { |c| c.replicable_name_plural }

      expect(names).to include(*expected_names)
    end
  end
end
