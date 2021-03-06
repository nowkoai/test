# frozen_string_literal: true

module Projects
  module Pipelines
    class StagesController < Projects::Pipelines::ApplicationController
      before_action :authorize_update_pipeline!

      urgency :low, [
        :play_manual
      ]

      def play_manual
        ::Ci::PlayManualStageService
          .new(@project, current_user, pipeline: pipeline)
          .execute(stage)

        respond_to do |format|
          format.json do
            render json: StageSerializer
              .new(project: @project, current_user: @current_user)
              .represent(stage)
          end
        end
      end

      private

      def stage
        @pipeline_stage ||= pipeline.find_stage_by_name!(params[:stage_name])
      end
    end
  end
end
