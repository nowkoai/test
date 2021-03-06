# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Delete do
  include GraphqlHelpers

  let_it_be(:runner) { create(:ci_runner) }

  let(:user) { create(:user) }
  let(:current_ctx) { { current_user: user } }

  let(:mutation_params) do
    { id: runner.to_global_id }
  end

  specify { expect(described_class).to require_graphql_authorizations(:delete_runner) }

  describe '#resolve' do
    subject do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when the user cannot admin the runner' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with invalid params' do
      it 'raises an error' do
        mutation_params[:id] = "invalid-id"

        expect { subject }.to raise_error(::GraphQL::CoercionError)
      end
    end

    context 'when required arguments are missing' do
      let(:mutation_params) { {} }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, "Arguments must be provided: id")
      end
    end

    context 'when user can delete owned runner' do
      let!(:project) { create(:project, creator_id: user.id) }
      let!(:project_runner) { create(:ci_runner, :project, description: 'Project runner', projects: [project]) }

      before do
        project.add_maintainer(user)
      end

      context 'with one associated project' do
        it 'deletes runner' do
          mutation_params[:id] = project_runner.to_global_id

          expect_next_instance_of(::Ci::Runners::UnregisterRunnerService, project_runner, current_ctx[:current_user]) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect { subject }.to change { Ci::Runner.count }.by(-1)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'with more than one associated project' do
        let!(:project2) { create(:project, creator_id: user.id) }
        let!(:two_projects_runner) { create(:ci_runner, :project, description: 'Two projects runner', projects: [project, project2]) }

        before do
          project2.add_maintainer(user)
        end

        it 'does not delete project runner' do
          mutation_params[:id] = two_projects_runner.to_global_id

          allow_next_instance_of(::Ci::Runners::UnregisterRunnerService) do |service|
            expect(service).not_to receive(:execute)
          end
          expect { subject }.not_to change { Ci::Runner.count }
          expect(subject[:errors]).to contain_exactly("Runner #{two_projects_runner.to_global_id} associated with more than one project")
        end
      end
    end

    context 'when admin can delete runner', :enable_admin_mode do
      let(:admin_user) { create(:user, :admin) }
      let(:current_ctx) { { current_user: admin_user } }

      it 'deletes runner' do
        expect_next_instance_of(::Ci::Runners::UnregisterRunnerService, runner, current_ctx[:current_user]) do |service|
          expect(service).to receive(:execute).once.and_call_original
        end

        expect { subject }.to change { Ci::Runner.count }.by(-1)
        expect(subject[:errors]).to be_empty
      end
    end
  end
end
