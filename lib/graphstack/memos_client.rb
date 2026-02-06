# frozen_string_literal: true

module Graphstack
  # Client for creating hosted markdown memos
  #
  # Usage:
  #   client = Graphstack.client.personagraph.memos
  #   result = client.create(content: "# My Memo\n\nSome content...")
  #   # => { url: "https://...", identifier: "abc123", ... }
  #
  class MemosClient
    BASE_PATH = "/api/v1/personagraph/memos"

    def initialize(client)
      @client = client
    end

    # Create a hosted markdown memo
    #
    # @param content [String] Markdown content (required)
    # @param title [String] Optional title for browser tab
    # @param conversation_id [String] Optional conversation ID to associate
    # @return [Hash] { url:, identifier:, id:, title:, created_at: } or { error: true, message: }
    def create(content:, title: nil, conversation_id: nil)
      response = @client.post(BASE_PATH, {
        content: content,
        title: title,
        conversation_id: conversation_id
      }.compact)

      parse_response(response)
    end

    private

    def parse_response(response)
      if response && !response[:error]
        {
          id: response.dig("data", "id"),
          identifier: response.dig("data", "identifier"),
          url: response.dig("data", "url"),
          title: response.dig("data", "title"),
          created_at: response.dig("data", "created_at")
        }
      else
        {
          error: true,
          message: response&.dig(:body, "error") || "Failed to create memo"
        }
      end
    end
  end
end
