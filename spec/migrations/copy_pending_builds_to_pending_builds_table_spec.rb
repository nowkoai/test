# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210520105029_copy_pending_builds_to_pending_builds_table.rb')

RSpec.describe CopyPendingBuildsToPendingBuildsTable do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:queue) { table(:ci_pending_builds) }
  let(:builds) { table(:ci_builds) }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')
    projects.create!(id: 123, name: 'sample', path: 'sample', namespace_id: 123)

    builds.create!(id: 1, project_id: 123, status: 'pending', type: 'Ci::Build', created_at: 4.days.ago, updated_at: 4.days.ago)
    builds.create!(id: 2, project_id: 123, status: 'pending', type: 'Ci::Build')
    builds.create!(id: 3, project_id: 123, status: 'pending', type: 'GenericCommitStatus')
    builds.create!(id: 4, project_id: 123, status: 'pending', type: 'GenericCommitStatus')
    builds.create!(id: 5, project_id: 123, status: 'pending', type: 'Ci::Bridge')
    builds.create!(id: 6, project_id: 123, status: 'pending', type: 'Ci::Build')
    builds.create!(id: 7, project_id: 123, status: 'running', type: 'Ci::Build')
    builds.create!(id: 8, project_id: 123, status: 'created', type: 'Ci::Build')
  end

  context 'when there are new pending builds present' do
    it 'migrates data' do
      migrate!

      expect(queue.all.count).to eq 2
      expect(queue.all.pluck(:build_id)).to match_array([2, 6])
    end
  end

  context 'when there are pending builds already migrated present' do
    before do
      queue.create!(id: 1, build_id: 2, project_id: 123)
    end

    it 'does not copy entries that have already been copied' do
      expect(queue.all.count).to eq 1

      migrate!

      expect(queue.all.count).to eq 2
      expect(queue.all.pluck(:build_id)).to match_array([2, 6])
    end
  end

  context 'when there is more than one batch of pending builds to migrate' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'correctly migrates data and exits after doing that' do
      migrate!

      expect(queue.all.count).to eq 2
      expect(queue.all.pluck(:build_id)).to match_array([2, 6])
    end
  end

  context 'when an old build has been recently updated' do
    before do
      builds.find(1).touch
    end

    it 'migrates it as well' do
      migrate!

      expect(queue.all.count).to eq 3
      expect(queue.all.pluck(:build_id)).to match_array([1, 2, 6])
    end
  end

  context 'when there is no data to migrate' do
    before do
      builds.all.delete_all
    end

    it 'does not raise an exception' do
      expect(builds.all.count).to eq 0

      expect { migrate! }.not_to raise_error
    end
  end
end
