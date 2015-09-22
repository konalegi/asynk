module Asynk
  class Publisher
    class << self
      def publish(routing_key, params = {})
        Asynk.broker.pubisher_channel_pool.with do |channel|
          exchange = channel.topic(Asynk.config[:mq_exchange])
          Asynk::Benchmark.measure_around("Sending asynk message to #{routing_key} with params: #{params}") do
            exchange.publish(params.to_json, routing_key: routing_key)
          end
        end
      end

      def sync_publish(routing_key, params = {})
        reply_queue = nil
        wait_timeout = params.delete(:timeout) || Asynk.config[:sync_publish_wait_timeout]
        load_cellulooid
        response = nil
        Asynk.broker.pubisher_channel_pool.with do |channel|
          exchange = channel.topic(Asynk.config[:mq_exchange])

          reply_queue = channel.queue('', exclusive: true)
          condition = Celluloid::Condition.new
          call_id = SecureRandom.uuid

          reply_queue.subscribe do |delivery_info, properties, payload|
            condition.signal(payload) if properties[:correlation_id] == call_id
          end

          Asynk::Benchmark.measure_around("Sending synk message to #{routing_key} with params: #{params}") do
            exchange.publish(params.to_json, routing_key: routing_key, correlation_id: call_id, reply_to: reply_queue.name)
            response = condition.wait(wait_timeout)
          end
        end
        reply_queue.delete rescue Asynk.logger.error 'Cannot close reply queue.'

        Asynk::Response.try_to_create_from_hash(response)
      end

      def load_cellulooid
        require 'celluloid'
        require 'celluloid/io'
      end
    end
  end
end