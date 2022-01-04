# frozen_string_literal: true

module EE
  module Gitlab
    module Security
      module ScanConfiguration
        extend ::Gitlab::Utils::Override

        override :available?
        def available?
          super || project.licensed_feature_available?(type)
        end

        override :configuration_path
        def configuration_path
          super if available? || always_available?
        end

        private

        override :configurable_scans
        def configurable_scans
          strong_memoize(:configurable_scans) do
            {
              dast: project_security_configuration_dast_path(project),
              dast_profiles: project_security_configuration_dast_scans_path(project),
              api_fuzzing: project_security_configuration_api_fuzzing_path(project),
              corpus_management: (project_security_configuration_corpus_management_path(project) if ::Feature.enabled?(:corpus_management_ui, project, default_enabled: :yaml))
            }.merge(super)
          end
        end

        def always_available?
          [:corpus_management, :dast_profiles].include?(type)
        end
      end
    end
  end
end
