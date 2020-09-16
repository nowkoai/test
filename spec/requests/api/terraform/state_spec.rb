# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::State do
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:maintainer) { create(:user, maintainer_projects: [project]) }

  let!(:state) { create(:terraform_state, :with_version, project: project) }

  let(:current_user) { maintainer }
  let(:auth_header) { user_basic_auth_header(current_user) }
  let(:project_id) { project.id }
  let(:state_name) { state.name }
  let(:state_path) { "/projects/#{project_id}/terraform/state/#{state_name}" }

  before do
    stub_terraform_state_object_storage(Terraform::StateUploader)
  end

  describe 'GET /projects/:id/terraform/state/:name' do
    subject(:request) { get api(state_path), headers: auth_header }

    context 'without authentication' do
      let(:auth_header) { basic_auth_header('bad', 'token') }

      it 'returns 401 if user is not authenticated' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'personal acceess token authentication' do
      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        it 'returns terraform state belonging to a project of given state name' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(state.reload.latest_file.read)
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns terraform state belonging to a project of given state name' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(state.reload.latest_file.read)
        end
      end
    end

    context 'job token authentication' do
      let(:auth_header) { job_basic_auth_header(job) }

      context 'with maintainer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: maintainer) }

        it 'returns terraform state belonging to a project of given state name' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(state.reload.latest_file.read)
        end

        it 'returns unauthorized if the the job is not running' do
          job.update!(status: :failed)
          request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with developer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: developer) }

        it 'returns terraform state belonging to a project of given state name' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(state.reload.latest_file.read)
        end
      end
    end
  end

  describe 'POST /projects/:id/terraform/state/:name' do
    let(:params) { { 'instance': 'example-instance', 'serial': '1' } }

    subject(:request) { post api(state_path), headers: auth_header, as: :json, params: params }

    context 'when terraform state with a given name is already present' do
      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        it 'updates the state' do
          expect { request }.to change { Terraform::State.count }.by(0)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'on Unicorn', :unicorn do
          it 'updates the state' do
            expect { request }.to change { Terraform::State.count }.by(0)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'without body' do
        let(:params) { nil }

        it 'returns no content if no body is provided' do
          request

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns forbidden' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when there is no terraform state of a given name' do
      let(:state_name) { 'example2' }

      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        it 'creates a new state' do
          expect { request }.to change { Terraform::State.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'on Unicorn', :unicorn do
          it 'creates a new state' do
            expect { request }.to change { Terraform::State.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'without body' do
        let(:params) { nil }

        it 'returns no content if no body is provided' do
          request

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns forbidden' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name' do
    subject(:request) { delete api(state_path), headers: auth_header }

    context 'with maintainer permissions' do
      let(:current_user) { maintainer }

      it 'deletes the state' do
        expect { request }.to change { Terraform::State.count }.by(-1)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with developer permissions' do
      let(:current_user) { developer }

      it 'returns forbidden' do
        expect { request }.to change { Terraform::State.count }.by(0)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /projects/:id/terraform/state/:name/lock' do
    let(:params) do
      {
        ID: '123-456',
        Version: '0.1',
        Operation: 'OperationTypePlan',
        Info: '',
        Who: "#{current_user.username}",
        Created: Time.now.utc.iso8601(6),
        Path: ''
      }
    end

    subject(:request) { post api("#{state_path}/lock"), headers: auth_header, params: params }

    it 'locks the terraform state' do
      request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'state is already locked' do
      before do
        state.update!(lock_xid: 'locked', locked_by_user: current_user)
      end

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'user does not have permission to lock the state' do
      let(:current_user) { developer }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name/lock' do
    let(:params) do
      {
        ID: lock_id,
        Version: '0.1',
        Operation: 'OperationTypePlan',
        Info: '',
        Who: "#{current_user.username}",
        Created: Time.now.utc.iso8601(6),
        Path: ''
      }
    end

    before do
      state.lock_xid = '123-456'
      state.save!
    end

    subject(:request) { delete api("#{state_path}/lock"), headers: auth_header, params: params }

    context 'with the correct lock id' do
      let(:lock_id) { '123-456' }

      it 'removes the terraform state lock' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with no lock id (force-unlock)' do
      let(:params) { {} }

      it 'removes the terraform state lock' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with an incorrect lock id' do
      let(:lock_id) { '456-789' }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'with a longer than 255 character lock id' do
      let(:lock_id) { '0' * 256 }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'user does not have permission to unlock the state' do
      let(:lock_id) { '123-456' }
      let(:current_user) { developer }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
