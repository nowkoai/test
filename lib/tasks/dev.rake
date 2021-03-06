# frozen_string_literal: true

task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Dev | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke

    Gitlab::Database::EachDatabase.each_database_connection do |connection|
      # Make sure DB statistics are up to date.
      connection.execute('ANALYZE')
    end

    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Dev | Eager load application"
  task load: :environment do
    Rails.configuration.eager_load = true
    Rails.application.eager_load!
  end
end
