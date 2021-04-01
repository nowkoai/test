# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansController, type: :request do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }

  shared_examples 'on-demand scans page' do
    include_context '"Security & Compliance" permissions' do
      let(:valid_request) { get path }

      before_request do
        project.add_developer(user)
        login_as(user)
      end
    end

    context 'feature available' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'user authorized' do
        before do
          project.add_developer(user)

          login_as(user)
        end

        it "can access page" do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user not authorized' do
        before do
          project.add_guest(user)

          login_as(user)
        end

        it "sees a 404 error" do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'feature not available' do
      before do
        project.add_developer(user)

        login_as(user)
      end

      it "sees a 404 error if the license doesn't support the feature" do
        stub_licensed_features(security_on_demand_scans: false)
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    it_behaves_like 'on-demand scans page' do
      let(:path) { project_on_demand_scans_path(project) }
    end
  end

  describe 'GET #new' do
    it_behaves_like 'on-demand scans page' do
      let(:path) { new_project_on_demand_scan_path(project) }
    end
  end

  describe 'GET #edit' do
    let_it_be(:dast_profile) { create(:dast_profile, project: project) }

    let(:dast_profile_id) { dast_profile.id }
    let(:edit_path) { edit_project_on_demand_scan_path(project, id: dast_profile_id) }

    it_behaves_like 'on-demand scans page' do
      let(:path) { edit_path }
    end

    context 'feature available and user can access page' do
      before do
        stub_licensed_features(security_on_demand_scans: true)

        project.add_developer(user)

        login_as(user)
      end

      context 'dast_profile exists in the database' do
        it 'includes a serialized dast_profile in the response body' do
          get edit_path

          json_data = {
            id: global_id_of(dast_profile),
            name: dast_profile.name,
            description: dast_profile.description,
            branch: { name: dast_profile.branch_name },
            site_profile_id: global_id_of(DastSiteProfile.new(id: dast_profile.dast_site_profile_id)),
            scanner_profile_id: global_id_of(DastScannerProfile.new(id: dast_profile.dast_scanner_profile_id))
          }.to_json

          on_demand_div = Nokogiri::HTML.parse(response.body).at_css('div#js-on-demand-scans-app')

          expect(on_demand_div.attributes['data-dast-scan'].value).to include(json_data)
        end
      end

      context 'dast_profile does not exist in the database' do
        let(:dast_profile_id) { 0 }

        it 'sees a 404 error' do
          get edit_path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
