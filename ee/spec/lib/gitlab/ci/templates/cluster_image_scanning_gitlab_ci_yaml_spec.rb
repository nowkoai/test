# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cluster-Image-Scanning.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Cluster-Image-Scanning') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { 'master' }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master' ) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
      create(:ci_variable, project: project, key: 'CIS_KUBECONFIG', value: '*')
    end

    context 'when project has no license' do
      it 'includes no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'by default' do
        it 'includes job' do
          expect(build_names).to match_array(%w[cluster_image_scanning])
        end
      end

      context 'with CIS_MAJOR_VERSION greater than 3' do
        before do
          create(:ci_variable, project: project, key: 'CIS_MAJOR_VERSION', value: '4')
        end

        it 'includes job' do
          expect(build_names).to match_array(%w[cluster_image_scanning])
        end
      end

      context 'when CLUSTER_IMAGE_SCANNING_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'CLUSTER_IMAGE_SCANNING_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end
    end
  end
end
