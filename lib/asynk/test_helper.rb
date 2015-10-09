module Asynk
  module TestHelper
    def publish_sync(routing_key, options)
      consumers = find_consumers_by_route(routing_key)
      raise "Cant find consumer by route: #{routing_key}" if consumers.empty?
      raise "No ability to test multiple consumer per route" if consumers.count > 1
      consumer = consumers.first

      bunny_mocked_channel = BunnyMockedChannel.new
      bunny_mocked_delivery_info = BuunyMockedDeliveryInfo.new(routing_key)
      bunny_mock_properties = BuunyMockedProperties.new

      message = Asynk::Message.new(bunny_mocked_delivery_info, bunny_mock_properties, options.to_json)
      consumer_instance = consumer.new(bunny_mocked_channel, bunny_mocked_delivery_info) do |result|
        self.asynk_response = result.kind_of?(String) ? result : result.to_json
      end

      consumer_instance.invoke_processing(message)
      asynk_response
    end

    def asynk_response=(response)
      @asynk_response = response
    end

    def asynk_response
      @asynk_response
    end

    def find_consumers_by_route(route)
      Asynk.consumers.select{ |consumer| consumer.routing_keys.any?{ |key| key == route } }
    end

    class BunnyMockedChannel
      def ack(*args); end
      def reject(*args); end
      def retry(*args); end
    end

    class BuunyMockedDeliveryInfo
      attr_reader :routing_key
      def initialize(routing_key); @routing_key = routing_key; end
      def exchange; end
      def delivery_tag; end
    end

    class BuunyMockedProperties
      def timestamp; Time.now; end
      def message_id; 1; end
    end
  end
end