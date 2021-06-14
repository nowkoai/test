# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "CI YML Templates" do
  using RSpec::Parameterized::TableSyntax
  subject { Gitlab::Ci::YamlProcessor.new(content).execute }

  let(:all_templates) { Gitlab::Template::GitlabCiYmlTemplate.all.map(&:full_name) }

  before do
    stub_feature_flags(
      redirect_to_latest_template_terraform: false,
      redirect_to_latest_template_security_dast: false,
      redirect_to_latest_template_security_api_fuzzing: false,
      redirect_to_latest_template_jobs_browser_performance_testing: false)
  end

  shared_examples 'require default stages to be included' do
    it 'require default stages to be included' do
      expect(subject.stages).to include(*Gitlab::Ci::Config::Entry::Stages.default)
    end
  end

  context 'that support autodevops' do
    non_autodevops_templates = [
      'Security/DAST-API.gitlab-ci.yml',
      'Security/API-Fuzzing.gitlab-ci.yml'
    ]

    where(:template_name) do
      all_templates - non_autodevops_templates
    end

    with_them do
      let(:content) do
        <<~EOS
          include:
            - template: #{template_name}

          concrete_build_implemented_by_a_user:
            stage: test
            script: do something
        EOS
      end

      it 'are valid with default stages' do
        expect(subject).to be_valid
      end

      include_examples 'require default stages to be included'
    end
  end

  context 'that do not support autodevops' do
    context 'when DAST API template' do
      # The DAST API template purposly excludes a stages
      # definition.

      let(:template_name) { 'Security/DAST-API.gitlab-ci.yml' }

      context 'with default stages' do
        let(:content) do
          <<~EOS
            include:
              - template: #{template_name}

            concrete_build_implemented_by_a_user:
              stage: test
              script: do something
          EOS
        end

        it { is_expected.not_to be_valid }
      end

      context 'with defined stages' do
        let(:content) do
          <<~EOS
            include:
              - template: #{template_name}

            stages:
              - build
              - test
              - deploy
              - dast

            concrete_build_implemented_by_a_user:
              stage: test
              script: do something
          EOS
        end

        it { is_expected.to be_valid }

        include_examples 'require default stages to be included'
      end
    end

    context 'when API Fuzzing template' do
      # The API Fuzzing template purposly excludes a stages
      # definition.

      let(:template_name) { 'Security/API-Fuzzing.gitlab-ci.yml' }

      context 'with default stages' do
        let(:content) do
          <<~EOS
            include:
              - template: #{template_name}

            concrete_build_implemented_by_a_user:
              stage: test
              script: do something
          EOS
        end

        it { is_expected.not_to be_valid }
      end

      context 'with defined stages' do
        let(:content) do
          <<~EOS
            include:
              - template: #{template_name}

            stages:
              - build
              - test
              - deploy
              - fuzz

            concrete_build_implemented_by_a_user:
              stage: test
              script: do something
          EOS
        end

        it { is_expected.to be_valid }

        include_examples 'require default stages to be included'
      end
    end
  end
end
