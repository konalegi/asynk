module Asynk
  class Publisher
    class << self
      def publish(routing_key, params = {})
        conn = Asynk.broker.amqp_connection

        ch       = conn.create_channel
        x        = ch.topic(Asynk.config[:mq_exchange])

        x.publish(params.to_json, routing_key: routing_key)
      ensure
        ch.close if ch
      end

      def sync_publish(routing_key, params = {})
        wait_timeout = params.delete(:timeout) || Asynk.config[:sync_publish_wait_timeout]
        load_cellulooid
        conn = Asynk.broker.amqp_connection
        ch   = conn.create_channel
        x    = ch.topic(Asynk.config[:mq_exchange])

        reply_queue = ch.queue('', exclusive: true)
        condition = Celluloid::Condition.new
        call_id = SecureRandom.uuid

        reply_queue.subscribe do |delivery_info, properties, payload|
          condition.signal(payload) if properties[:correlation_id] == call_id
        end

        x.publish(params.to_json, routing_key: routing_key, correlation_id: call_id, reply_to: reply_queue.name)
        Asynk::Response.try_to_create_from_hash(condition.wait(wait_timeout))
      ensure
        ch.close if ch
      end

      def load_cellulooid
        require 'celluloid'
        require 'celluloid/io'
      end
    end
  end
end