# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  config.base_class = 'ApplicationExperiment'
  config.mount_at = '/-/experiment'
  config.cache = Gitlab::Experiment::Cache::RedisHashStore.new(
    pool: ->(&block) { Gitlab::Redis::SharedState.with { |redis| block.call(redis) } }
  )
  config.tracking_behavior = lambda do |action, event_args|
    Gitlab::Tracking.event(name, action.to_s, **event_args.merge(
      context: (event_args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0', signature
      )
    ))
  end
end

# TODO: This shim should be removed after the feature flag is rolled out, as
#   it only exists to facilitate the feature flag control of the behavior.
module Gitlab::Experiment::MiddlewareWithFeatureFlags
  attr_reader :app

  def call(env)
    return app.call(env) unless Feature.enabled?(:gitlab_experiment_middleware)

    super
  end
end

Gitlab::Experiment::Middleware.prepend(Gitlab::Experiment::MiddlewareWithFeatureFlags)
