# frozen_string_literal: true

module Graphstack
  # Email-specific client for sending messages via email (Resend)
  #
  # Usage:
  #   client = Graphstack.client.personagraph.email
  #
  #   # Send to existing conversation (replies to thread)
  #   result = client.send_message(conversation_id: "uuid", content: "Your reply...")
  #   # => { conversation_id: "uuid", entry_id: "uuid", ... }
  #
  #   # Get conversation messages
  #   messages = client.get_messages(conversation_id)
  #
  class EmailClient
    BASE_PATH = "/api/v1/personagraph/email"
    CONVERSATIONS_PATH = "/api/v1/personagraph/conversations"

    def initialize(client)
      @client = client
    end

    # Send an email message
    #
    # @param conversation_id [String] Existing conversation ID (required for email replies)
    # @param content [String] Message content to send
    # @return [Hash] Response with conversation_id, entry_id, etc.
    def send_message(conversation_id:, content:)
      response = @client.post("#{BASE_PATH}/send", {
        conversation_id: conversation_id,
        content: content
      })

      parse_send_response(response)
    end

    # Get all messages in a conversation
    #
    # @param conversation_id [String] Conversation ID
    # @return [Hash] { messages: [...] } or { error: true, status: ..., message: ... }
    def get_messages(conversation_id)
      response = @client.get("#{CONVERSATIONS_PATH}/#{conversation_id}/messages")

      if response && !response[:error]
        { messages: response.dig("data", "messages") || [] }
      else
        {
          error: true,
          status: response&.dig(:status),
          message: response&.dig(:body, "error") || "Failed to fetch messages"
        }
      end
    end

    private

    def parse_send_response(response)
      if response && !response[:error]
        {
          conversation_id: response.dig("data", "conversation_id"),
          entry_id: response.dig("data", "entry_id"),
          content: response.dig("data", "content"),
          status: response.dig("data", "status"),
          created_at: response.dig("data", "created_at")
        }
      else
        { error: true, message: response&.dig(:body) || "Failed to send message" }
      end
    end
  end
end
