module Asynk
  module Consumer

    def self.included(base)
      base.extend(ClassMethods)
      Asynk.register_consumer(base)
    end

    def initialize(channel, delivery_info)
      @channel, @delivery_info = channel, delivery_info
    end

    def ack!
      @channel.ack(@delivery_info.delivery_tag)
    end

    def reject!
      @channel.reject(@delivery_info.delivery_tag)
    end

    def retry!
      @channel.retry(@delivery_info.delivery_tag)
    end

    def logger
      Asynk.logger
    end

    module ClassMethods
      attr_reader :routing_keys, :queue_name, :subscribe_arguments, :queue_options

      # Add one or more routing keys to the set of routing keys the consumer
      # wants to subscribe to.
      def set_consume(*routing_keys)
        @routing_keys = routing_keys
      end

      # Explicitly set the queue name
      def set_queue(name, options = {})
        @queue_name = name
        @queue_options = options
      end

      # Allow to specify custom arguments that will be passed when creating the queue.
      def set_subscribe_arguments(arguments = {})
        @subscribe_arguments = arguments
      end

      def set_concurrency(size)
        @concurrency = size
      end

      def concurrency
        @concurrency || Asynk.config[:default_consumer_concurrency]
      end

      def set_sync(sync)
        @sync = sync
      end

      def sync?
        @sync || Asynk.config[:default_sync]
      end

    end
  end
end