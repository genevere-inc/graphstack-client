# frozen_string_literal: true

require "svix"

module Graphstack
  # Helper for handling incoming webhooks from Graphstack
  #
  # Uses Svix for signature verification - Graphstack sends webhooks with
  # Svix-compatible headers (svix-id, svix-timestamp, svix-signature).
  #
  # Usage:
  #   # Verify and parse in one step
  #   event = Graphstack::Webhook.verify_and_parse!(
  #     payload: request.raw_post,
  #     headers: {
  #       "svix-id" => request.headers["svix-id"],
  #       "svix-timestamp" => request.headers["svix-timestamp"],
  #       "svix-signature" => request.headers["svix-signature"]
  #     }
  #   )
  #
  class Webhook
    class SignatureVerificationError < StandardError; end

    # Verify the webhook signature and parse the event
    #
    # @param payload [String] Raw request body
    # @param headers [Hash] Hash containing svix-id, svix-timestamp, svix-signature
    # @param secret [String] Optional webhook secret (defaults to Graphstack.configuration.webhook_secret)
    # @return [Event] Parsed and verified event
    # @raise [SignatureVerificationError] if signature is invalid
    def self.verify_and_parse!(payload:, headers:, secret: nil)
      secret ||= Graphstack.configuration&.webhook_secret
      raise SignatureVerificationError, "No webhook secret configured" if secret.nil? || secret.empty?

      begin
        wh = Svix::Webhook.new(secret)
        verified_data = wh.verify(payload, headers)
        Event.new(verified_data)
      rescue Svix::WebhookVerificationError => e
        raise SignatureVerificationError, "Signature verification failed: #{e.message}"
      end
    end

    # Verify signature without raising (returns boolean)
    #
    # @param payload [String] Raw request body
    # @param headers [Hash] Hash containing svix-id, svix-timestamp, svix-signature
    # @param secret [String] Optional webhook secret
    # @return [Boolean] true if signature is valid, false otherwise
    def self.verify?(payload:, headers:, secret: nil)
      verify_and_parse!(payload: payload, headers: headers, secret: secret)
      true
    rescue SignatureVerificationError
      false
    end

    # Parse a webhook payload without verification (use only if already verified)
    #
    # @param payload [String] Raw JSON payload
    # @return [Event] Parsed event object
    def self.parse(payload)
      data = payload.is_a?(String) ? JSON.parse(payload) : payload
      Event.new(deep_symbolize_keys(data))
    end

    # Deep symbolize keys helper (avoids Rails dependency)
    def self.deep_symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
        result[new_key] = new_value
      end
    end
  end

  # Represents a webhook event from Graphstack
  class Event
    attr_reader :data

    def initialize(data)
      @data = data.is_a?(Hash) ? IndifferentHash.new(data) : data
    end

    # Event type (e.g., "message.created")
    def type
      data[:event]
    end

    # Timestamp of the event
    def timestamp
      data[:timestamp]
    end

    # Conversation ID
    def conversation_id
      dig(:data, :conversation, :id)
    end

    # Entry (message) ID - maps to Graphstack's message.id
    def entry_id
      dig(:data, :message, :id)
    end

    # Message role ("user" or "assistant")
    def role
      dig(:data, :message, :role)
    end

    # Message content
    def content
      dig(:data, :message, :content)
    end

    # Sender name
    def from_name
      dig(:data, :message, :from_name)
    end

    # Sender identifier (phone number, email, etc.)
    def from_id
      dig(:data, :message, :from_id)
    end

    # Message timestamp
    def message_timestamp
      dig(:data, :message, :timestamp)
    end

    # Message status
    def status
      dig(:data, :message, :status)
    end

    # Gateway message ID (Linq message ID, etc.)
    def gateway_message_id
      dig(:data, :message, :gateway_message_id)
    end

    # Conversation scenario
    def scenario
      dig(:data, :message, :scenario) || dig(:data, :conversation, :scenario)
    end

    # Sender contact ID (if known contact)
    def sender_contact_id
      dig(:data, :message, :sender_contact_id)
    end

    # Conversation gateway
    def gateway
      dig(:data, :conversation, :gateway)
    end

    # Conversation gateway identifier (e.g., Linq chat_id)
    def gateway_identifier
      dig(:data, :conversation, :gateway_identifier)
    end

    # Conversation medium (chat, email, meeting)
    def medium
      dig(:data, :conversation, :medium)
    end

    # Conversation status
    def conversation_status
      dig(:data, :conversation, :status)
    end

    # Participants in the conversation
    def participants
      dig(:data, :conversation, :participants) || []
    end

    # Introducer info (for group introductions)
    def introducer
      dig(:data, :conversation, :introducer)
    end

    # Account persona info
    def account_persona_id
      dig(:data, :account_persona, :id)
    end

    def persona_id
      dig(:data, :account_persona, :persona_id)
    end

    def persona_handle
      dig(:data, :account_persona, :persona_handle)
    end

    # Check if this is a user message
    def user_message?
      role == "user"
    end

    # Check if this is an assistant message
    def assistant_message?
      role == "assistant"
    end

    # Check if this is a test event
    def test?
      type == "test"
    end

    # Raw message data
    def message_data
      dig(:data, :message) || {}
    end

    # Raw conversation data
    def conversation_data
      dig(:data, :conversation) || {}
    end

    private

    def dig(*keys)
      keys.reduce(data) do |obj, key|
        return nil unless obj.is_a?(Hash) || obj.respond_to?(:[])
        obj[key]
      end
    end
  end

  # Simple indifferent access hash (avoids Rails dependency)
  class IndifferentHash < Hash
    def initialize(hash = {})
      super()
      hash.each do |key, value|
        self[key.to_sym] = value.is_a?(Hash) ? IndifferentHash.new(value) : value
      end
    end

    def [](key)
      super(key.to_sym)
    end

    def dig(*keys)
      keys.reduce(self) do |obj, key|
        return nil unless obj.is_a?(Hash) || obj.respond_to?(:[])
        obj[key.to_sym]
      end
    end
  end
end
