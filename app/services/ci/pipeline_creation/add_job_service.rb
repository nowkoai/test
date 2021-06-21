# frozen_string_literal: true

module Ci
  module PipelineCreation
    class AddJobService
      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline

        raise "Pipeline must be persisted for this service to be used" unless @pipeline.persisted?
      end

      def execute(job, save: true)
        assign_pipeline_attributes(job)

        Ci::Pipeline.transaction do
          BulkInsertableAssociations.with_bulk_insert { job.save! } if save

          job.update_older_statuses_retried! if Feature.enabled?(:ci_fix_commit_status_retried, @pipeline.project, default_enabled: :yaml)
        end

        job
      end

      private

      def assign_pipeline_attributes(job)
        # these also ensures other invariants such as
        # a job takes project and ref from the pipeline it belongs to
        job.pipeline = @pipeline
        job.project = @pipeline.project
        job.ref = @pipeline.ref
      end
    end
  end
end
