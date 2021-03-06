# frozen_string_literal: true

module Backup
  class Artifacts < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('artifacts', JobArtifactUploader.root, excludes: ['tmp'])
    end

    def human_name
      _('artifacts')
    end
  end
end
