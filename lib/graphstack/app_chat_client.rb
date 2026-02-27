# frozen_string_literal: true

module Graphstack
  # App Chat client for in-app messaging (no external delivery)
  #
  # Usage:
  #   client = Graphstack.client.personagraph.app_chat
  #
  #   # Send a message (creates conversation if needed)
  #   result = client.send_message(to: ["user-uuid"], content: "Hello!")
  #   # => { conversation_id: "uuid", entry_id: "uuid", ... }
  #
  #   # Send to existing conversation
  #   result = client.send_message(conversation_id: "uuid", content: "Follow up!", role: "assistant")
  #
  #   # Get conversation messages
  #   messages = client.get_messages(conversation_id)
  #
  class AppChatClient
    BASE_PATH = "/api/v1/personagraph/app_chat"
    CONVERSATIONS_PATH = "/api/v1/personagraph/conversations"

    def initialize(client)
      @client = client
    end

    # Send a message via app chat
    #
    # @param content [String] Message content
    # @param to [Array<String>] Participant identifiers (for new conversations)
    # @param conversation_id [String] Existing conversation ID (for follow-ups)
    # @param role [String] Message role - 'user' or 'assistant' (default: 'user')
    # @param from_name [String] Sender display name
    # @param from_id [String] Sender identifier
    # @return [Hash] Response with conversation_id, entry_id, etc.
    def send_message(content:, to: nil, conversation_id: nil, role: "user", from_name: nil, from_id: nil, attachment_urls: nil)
      unless to.present? || conversation_id.present?
        return { error: true, message: "Either 'to' or 'conversation_id' is required" }
      end

      response = @client.post("#{BASE_PATH}/send", {
        to: to,
        conversation_id: conversation_id,
        content: content,
        role: role,
        from_name: from_name,
        from_id: from_id,
        attachment_urls: attachment_urls
      }.compact)

      parse_send_response(response)
    end

    # Get messages in a conversation
    #
    # @param conversation_id [String] Conversation ID
    # @param limit [Integer, nil] Optional limit - return only the N most recent messages
    # @return [Hash] { messages: [...] } or { error: true, status: ..., message: ... }
    def get_messages(conversation_id, limit: nil)
      params = {}
      params[:limit] = limit if limit.present?

      response = @client.get("#{CONVERSATIONS_PATH}/#{conversation_id}/messages", params)

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
