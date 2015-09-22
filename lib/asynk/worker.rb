module Asynk
  class Worker
    include Celluloid::IO

    def initialize(bunny_connection, consumer, instance_id)
      @instance_id = instance_id
      @consumer = consumer
      @ch = bunny_connection.create_channel
      @ch.prefetch(1)

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
      start_time = Time.now.to_f
      message = Asynk::Message.new(delivery_info, properties, payload)
      consumer_instance = @consumer.new(@ch, delivery_info) do |result|
        Asynk.logger.debug "#{@consumer.name}:#{@instance_id} Sending message back: #{result.to_s}. " +
          "Completed In: #{((Time.now.to_f - start_time)*1000).round(2)} ms."
        @default_exchange.publish(result.to_json, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
      end

      Asynk.logger.info "#{@consumer.name}:#{@instance_id} Got Message: #{message}"
      consumer_instance.invoke_processing(message)
    end

    def shutdown
      Asynk.logger.info "#{@consumer.name}:#{@instance_id} stopping..."
      @ch.close
    end

    private

  end
end