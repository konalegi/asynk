module Asynk
  class Worker
    include Celluloid::IO

    def initialize(bunny_connection, consumer, instance_id)
      @instance_id = instance_id
      @consumer = consumer
      @ch = bunny_connection.create_channel

      @default_exchange = @ch.default_exchange

      x = @ch.topic(Asynk.config[:mq_exchange])
      q = @ch.queue(consumer.queue_name, @consumer.queue_options)

      @consumer.routing_keys.each{ |routing_key| q.bind(x, routing_key: routing_key) }
      q.subscribe(@consumer.subscribe_arguments, &method(:on_event))

      Asynk.logger.debug ["#{@consumer.name}:#{@instance_id} worker accepting connections. ",
              "                  mq_exchange:   #{Asynk.config[:mq_exchange]}",
              "                  queue_name:    #{@consumer.queue_name}",
              "                  queue_options: #{@consumer.queue_options}",
              "                  routing_keys:  #{@consumer.routing_keys}"
      ].join("\r\n")
    end

    def on_event(delivery_info, properties, payload)
      message = Asynk::Message.new(delivery_info, properties, payload)
      consumer_instance = @consumer.new(@ch, delivery_info) do |result|
        Asynk.logger.debug "Sending message back: #{result.to_s}"
        @default_exchange.publish(result.to_json, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
      end
      consumer_instance.invoke_processing(message)
      Asynk.logger.info "Got Message: #{message}"

    end

    def shutdown
      Asynk.logger.info "#{@consumer.name}:#{@instance_id} stopping..."
      @ch.close
    end

    private

  end
end