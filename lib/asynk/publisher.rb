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
        condition.wait
      end
    end
  end
end