module Asynk
  module Consumer

    def self.included(base)
      base.extend(ClassMethods)
      base.include ActiveSupport::Rescuable
      Asynk.register_consumer(base)
    end

    def initialize(channel, delivery_info, &block)
      @channel = channel
      @delivery_info = delivery_info
      @callback_block = block
    end

    def ack!
      @channel.ack(@delivery_info.delivery_tag)
    end

    def reject!
      @channel.reject(@delivery_info.delivery_tag)
    end

    def requeue!
      @channel.reject(@delivery_info.delivery_tag, true)
    end

    def logger
      Asynk.logger
    end

    def respond(result)
      @callback_block.call(result)
    end

    def invoke_processing(message)
      method_for_exec = (self.class.route_ending_as_action? && message.routing_key) ?
                          self.class.action_name_from_routing_key(message.routing_key) : :process

      begin
        public_send(method_for_exec, message)
      rescue Exception => ex
        raise(ex) unless rescue_with_handler(ex)
      end
    end

    module ClassMethods
      attr_reader :routing_keys, :subscribe_arguments, :queue_options

      def set_consume(*routing_keys)
        @routing_keys = routing_keys
      end

      def set_route_ending_as_action(value)
        @route_ending_as_action = value
      end

      def route_ending_as_action?
        @route_ending_as_action || false
      end

      def set_queue_name(options = {})
        @queue_name = name
      end

      def set_queue_options(options = {})
        @queue_options = options
      end

      def queue_name
        return @queue_name unless @queue_name.nil?
        app_name = Rails.application.class.parent_name.dup.underscore if defined?(Rails)
        queue_name = ActiveSupport::Inflector.underscore(self.name.gsub(/::/, '.'))
        queue_name = [app_name, queue_name].join('.') if app_name
        queue_name
      end

      def set_subscribe_arguments(arguments = {})
        @subscribe_arguments = arguments
      end

      def set_concurrency(size)
        @concurrency = size
      end

      def concurrency
        @concurrency || Asynk.config[:default_consumer_concurrency]
      end

      def action_name_from_routing_key(routing_key)
        splitted = routing_key.split('.')
        raise 'There now action in routing_key' if splitted.empty? || splitted.count < 2
        splitted.last.to_sym
      end

    end
  end
end