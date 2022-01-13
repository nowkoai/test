# frozen_string_literal: true

module Security
  class TrainingProvider < ApplicationRecord
    self.table_name = 'security_training_providers'

    has_many :trainings, inverse_of: :provider, class_name: 'Security::Training'

    # These are the virtual attributes
    # generated by the `for_project` scope.
    attribute :is_enabled, :boolean
    attribute :is_primary, :boolean

    validates :name, presence: true, length: { maximum: 256 }
    validates :description, length: { maximum: 512 }
    validates :url, presence: true, length: { maximum: 512 }
    validates :logo_url, length: { maximum: 512 }

    scope :for_project, -> (project, only_enabled: false) do
      joins("LEFT OUTER JOIN security_trainings st ON st.provider_id = security_training_providers.id AND st.project_id = #{project.id}")
        .select(default_select_columns)
        .select('CASE WHEN st.id IS NULL THEN false ELSE true END AS is_enabled')
        .select('COALESCE(st.is_primary, FALSE) AS is_primary')
        .tap { |relation| relation.where!('st.id IS NOT NULL') if only_enabled }
    end
  end
end
