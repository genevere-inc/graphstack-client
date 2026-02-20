# frozen_string_literal: true

require "faraday"
require "svix"

require_relative "graphstack/version"
require_relative "graphstack/configuration"
require_relative "graphstack/client"
require_relative "graphstack/personagraph_client"
require_relative "graphstack/rcs_client"
require_relative "graphstack/email_client"
require_relative "graphstack/app_chat_client"
require_relative "graphstack/memos_client"
require_relative "graphstack/webhook"

module Graphstack
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client ||= Client.new(
        api_key: configuration.api_key,
        base_url: configuration.base_url
      )
    end

    def reset!
      @configuration = nil
      @client = nil
    end
  end
end
