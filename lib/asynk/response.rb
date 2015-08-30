require 'json'
module Asynk
  class Response
    attr_reader :status, :body, :error_message

    def initialize(status: , body: nil, error_message: nil)
      @status, @body, @error_message = status, body, error_message
    end

    def success?; @status.to_s == 'ok'; end
    def fail?; !success?; end

    def to_h(options = {})
      { status: @status, body: @body, error_message: @error_message }
    end

    def to_s
      to_h
    end

    alias_method :to_s, :to_h
    alias_method :as_json, :to_h
    alias_method :inspect, :to_s

    def self.try_to_create_from_hash(payload)
      return nil if payload.nil?
      parsed_payload = try_parse_json(payload)
      return payload unless parsed_payload
      return payload unless parsed_payload.kind_of?(Hash)
      hiwa = parsed_payload.with_indifferent_access
      return payload unless (hiwa.has_key?(:status) && hiwa.has_key?(:body) && hiwa.has_key?(:error_message))
      new(status: hiwa[:status], body: hiwa[:body], error_message: hiwa[:error_message])
    end

    def self.try_parse_json(str)
      begin
        JSON.parse(str)
      rescue JSON::ParserError => e
        return false
      end
    end
  end
end