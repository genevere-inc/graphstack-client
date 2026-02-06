# frozen_string_literal: true

module Graphstack
  class Configuration
    attr_accessor :api_key, :base_url, :webhook_secret

    def initialize
      @api_key = nil
      @base_url = "https://api.graphstack.io"
      @webhook_secret = nil
    end
  end
end
