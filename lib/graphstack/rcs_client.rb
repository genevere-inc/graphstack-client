# frozen_string_literal: true

module Graphstack
  # RCS-specific client for sending messages via RCS/iMessage
  #
  # Usage:
  #   client = Graphstack.client.personagraph.rcs
  #
  #   # Send a message (creates conversation if needed)
  #   result = client.send_message(to: ["+15551234567"], content: "Hello!")
  #   # => { conversation_id: "uuid", entry_id: "uuid", ... }
  #
  #   # Send to existing conversation
  #   result = client.send_message(conversation_id: "uuid", content: "Follow up!")
  #
  #   # Typing indicators
  #   client.start_typing(conversation_id)
  #   client.stop_typing(conversation_id)
  #
  #   # React to a message
  #   client.react(entry_id, reaction: "love")
  #
  #   # Share contact card
  #   client.share_contact(conversation_id)
  #
  #   # Get conversation messages
  #   messages = client.get_messages(conversation_id)
  #
  class RcsClient
    BASE_PATH = "/api/v1/personagraph/rcs"
    CONVERSATIONS_PATH = "/api/v1/personagraph/conversations"

    def initialize(client)
      @client = client
    end

    # Send an RCS message
    #
    # @param to [Array<String>] Phone numbers in E.164 format (for new conversations)
    # @param conversation_id [String] Existing conversation ID (for follow-ups)
    # @param content [String] Message content to send
    # @return [Hash] Response with conversation_id, entry_id, etc.
    def send_message(content:, to: nil, conversation_id: nil)
      unless to || conversation_id
        return { error: true, message: "Either 'to' or 'conversation_id' is required" }
      end

      response = @client.post("#{BASE_PATH}/send", {
        to: to,
        conversation_id: conversation_id,
        content: content
      }.compact)

      parse_send_response(response)
    end

    # Start typing indicator
    #
    # @param conversation_id [String] Conversation ID
    # @return [Hash] { success: true/false }
    def start_typing(conversation_id)
      response = @client.post("#{BASE_PATH}/typing", {
        conversation_id: conversation_id
      })
      { success: response && !response[:error] }
    end

    # Stop typing indicator
    #
    # @param conversation_id [String] Conversation ID
    # @return [Hash] { success: true/false }
    def stop_typing(conversation_id)
      response = @client.delete("#{BASE_PATH}/typing", {
        conversation_id: conversation_id
      })
      { success: response && !response[:error] }
    end

    # React to a message
    #
    # @param entry_id [String] Message/entry ID to react to
    # @param reaction [String] Reaction type (love, laugh, like, etc.)
    # @return [Hash] { success: true/false }
    def react(entry_id, reaction:)
      response = @client.post("#{BASE_PATH}/react", {
        entry_id: entry_id,
        reaction: reaction
      })
      { success: response && !response[:error] }
    end

    # Share contact card in conversation
    #
    # @param conversation_id [String] Conversation ID
    # @param text [String] Optional message to send with the contact card
    # @return [Hash] { success: true/false }
    def share_contact(conversation_id, text: nil)
      params = { conversation_id: conversation_id }
      params[:text] = text if text

      response = @client.post("#{BASE_PATH}/share_contact", params)
      { success: response && !response[:error] }
    end

    # Get messages in a conversation
    #
    # @param conversation_id [String] Conversation ID
    # @param limit [Integer, nil] Optional limit - return only the N most recent messages
    # @return [Hash] { messages: [...] } or { error: true, status: ..., message: ... }
    def get_messages(conversation_id, limit: nil)
      params = {}
      params[:limit] = limit if limit

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
