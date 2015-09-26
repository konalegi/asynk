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

      Asynk.logger.info ["#{@consumer.name}:#{@instance_id} worker accepting connections. ",
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
        @default_exchange.publish(convert_to_valid_json_string(result), routing_key: properties.reply_to, correlation_id: properties.correlation_id)

        if Asynk.config[:respond_back_execution_time]
          Asynk.logger.info "Responded to message #{message.routing_key}:#{message.message_id} In: #{((Time.now.to_f - start_time)*1000).round(2)} ms."
        end

        Asynk.logger.debug "#{@consumer.name}:#{@instance_id} Respoding to message id: #{message.message_id} with: #{result.to_s}. "
      end

      Asynk.logger.info "#{@consumer.name}:#{@instance_id} Got message #{message.routing_key}:#{message.message_id} with payload: #{message.body}"
      consumer_instance.invoke_processing(message)
    end

    def shutdown
      Asynk.logger.info "#{@consumer.name}:#{@instance_id} stopping..."
      @ch.close
    end

    private
      def convert_to_valid_json_string(data)
        data = '' if data.nil?
        data.is_a?(String) ? data : data.to_json
      end

  end
end