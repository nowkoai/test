# frozen_string_literal: true

module ResolvesOrchestrationPolicy
  extend ActiveSupport::Concern

  included do
    include Gitlab::Graphql::Authorize::AuthorizeResource

    calls_gitaly!

    alias_method :project, :object

    private

    def authorize!
      Ability.allowed?(
        context[:current_user], :security_orchestration_policies, policy_configuration.security_policy_management_project
      ) || raise_resource_not_available_error!
    end

    def policy_configuration
      @policy_configuration ||= project.security_orchestration_policy_configuration
    end

    def valid?
      policy_configuration.present? && policy_configuration.policy_configuration_valid?
    end
  end
end
