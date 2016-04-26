module Asynk
  class Publisher
    class PublisherError < RuntimeError; end

    class << self
      def publish(routing_key, params = {})
        message_id = params.delete(:message_id) || generate_message_id
        channel = Asynk.broker.amqp_connection.create_channel
        exchange = channel.topic(Asynk.config[:mq_exchange])
        publish_time = Asynk::Benchmark.measure_around do
          exchange.publish(params.to_json, message_id: message_id, routing_key: routing_key)
        end

        if Asynk.config[:publisher_execution_time]
          Asynk.logger.info "Sending async message #{routing_key}:#{message_id} with params: #{params}. Completed In: #{publish_time} ms."
        end

      ensure
        channel.close if channel
      end

      def sync_publish(routing_key, params = {})
        Asynk::SyncPublisher.new(routing_key, params).send
      end

      def generate_message_id(legnth = 8)
        SecureRandom.hex(legnth)
      end
    end
  end
end
