# frozen_string_literal: true

module Integrations
  class SlackSlashCommands < BaseSlashCommands
    include Ci::TriggersHelper

    def title
      'Slack slash commands'
    end

    def description
      "Perform common operations in Slack."
    end

    def self.to_param
      'slack_slash_commands'
    end

    def trigger(params)
      # Format messages to be Slack-compatible
      super.tap do |result|
        result[:text] = format(result[:text]) if result.is_a?(Hash)
      end
    end

    def chat_responder
      ::Gitlab::Chat::Responder::Slack
    end

    private

    def format(text)
      ::Slack::Messenger::Util::LinkFormatter.format(text) if text
    end
  end
end
