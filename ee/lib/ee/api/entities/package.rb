# frozen_string_literal: true

module EE
  module API
    module Entities
      class Package < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        extend EntityHelpers

        expose :id
        expose :name
        expose :version
        expose :package_type

        expose :_links do
          expose :web_path do |package|
            ::Gitlab::Routing.url_helpers.project_package_path(package.project, package)
          end

          expose :delete_api_path, if: can_destroy(:package, &:project) do |package|
            expose_url api_v4_projects_packages_path(package_id: package.id, id: package.project_id)
          end
        end

        expose :created_at
        expose :project_id, if: ->(_, opts) { opts[:group] }
        expose :project_path, if: ->(obj, opts) { opts[:group] && Ability.allowed?(opts[:user], :read_project, obj.project) }
        expose :tags

        expose :pipeline, if: ->(obj) { obj.build_info } do |package|
          ::API::Entities::Pipeline.represent package.build_info.pipeline, only: [:created_at, :id, :sha, :ref, :status, :updated_at, :web_url, user: [:name, :avatar_url]]
        end

        private

        def project_path
          object.project.full_path
        end
      end
    end
  end
end
