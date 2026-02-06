# frozen_string_literal: true

module Graphstack
  # Main API client for communicating with Graphstack
  #
  # Usage:
  #   Graphstack.configure do |config|
  #     config.api_key = ENV['GRAPHSTACK_API_KEY']
  #     config.base_url = ENV['GRAPHSTACK_BASE_URL']
  #   end
  #
  #   # Send an RCS message (creates conversation if needed)
  #   Graphstack.client.personagraph.rcs.send_message(to: ["+15551234567"], content: "Hello!")
  #
  #   # Typing indicators
  #   Graphstack.client.personagraph.rcs.start_typing(conversation_id)
  #   Graphstack.client.personagraph.rcs.stop_typing(conversation_id)
  #
  #   # Reactions
  #   Graphstack.client.personagraph.rcs.react(entry_id, reaction: "love")
  #
  #   # Contact card
  #   Graphstack.client.personagraph.rcs.share_contact(conversation_id)
  #
  class Client
    DEFAULT_BASE_URL = "https://api.graphstack.io"

    attr_reader :api_key, :base_url

    def initialize(api_key:, base_url: nil)
      @api_key = api_key
      @base_url = base_url || DEFAULT_BASE_URL
    end

    # Service-specific sub-clients
    def personagraph
      @personagraph ||= PersonagraphClient.new(self)
    end

    # Low-level HTTP methods for sub-clients
    def get(path, params = {})
      response = connection.get(path, params) do |req|
        req.headers.merge!(headers)
      end
      handle_response(response)
    end

    def post(path, body = {})
      response = connection.post(path) do |req|
        req.headers.merge!(headers)
        req.body = body.to_json
      end
      handle_response(response)
    end

    def delete(path, body = {})
      response = connection.delete(path) do |req|
        req.headers.merge!(headers)
        req.body = body.to_json unless body.empty?
      end
      handle_response(response)
    end

    private

    def connection
      @connection ||= Faraday.new(url: base_url) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def headers
      {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    def handle_response(response)
      if response.success?
        response.body
      else
        {
          error: true,
          status: response.status,
          body: response.body
        }
      end
    end
  end
end
