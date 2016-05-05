module Asynk
  class Publisher
    class PublisherError < RuntimeError; end

    class << self
      def publish(routing_key, params = {})
        global_start_time = Asynk::Benchmark.start if Asynk.config[:publisher_execution_time]
        message_id = params.delete(:message_id) || generate_message_id

        Asynk.broker.pool.with do |channel, exchange, reply_queue|
          exchange.publish(params.to_json, message_id: message_id, routing_key: routing_key)
        end

        if Asynk.config[:publisher_execution_time]
          Asynk.logger.info "Sending async message #{routing_key}:#{message_id} with params: #{params}. Completed In: #{Asynk::Benchmark.end(global_start_time)} ms."
        end
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
