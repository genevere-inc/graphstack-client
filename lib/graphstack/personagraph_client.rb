# frozen_string_literal: true

module Graphstack
  # Personagraph service client - handles messaging across channels
  #
  # Usage:
  #   Graphstack.client.personagraph.rcs.send_message(to: ["+15551234567"], content: "Hello!")
  #   Graphstack.client.personagraph.rcs.start_typing(conversation_id)
  #
  class PersonagraphClient
    def initialize(client)
      @client = client
    end

    # RCS/iMessage gateway
    def rcs
      @rcs ||= RcsClient.new(@client)
    end

    # Hosted markdown memos
    def memos
      @memos ||= MemosClient.new(@client)
    end

    # Email gateway
    def email
      @email ||= EmailClient.new(@client)
    end

    # App chat gateway (in-app messaging, no external delivery)
    def app_chat
      @app_chat ||= AppChatClient.new(@client)
    end

    # Future gateways:
    # def slack
    #   @slack ||= SlackClient.new(@client)
    # end
  end
end
