module Asynk
  class Publisher
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
        message_id = params.delete(:message_id) || generate_message_id
        wait_timeout = params.delete(:timeout) || Asynk.config[:sync_publish_wait_timeout]
        load_cellulooid
        response = nil

        channel = Asynk.broker.amqp_connection.create_channel
        exchange = channel.topic(Asynk.config[:mq_exchange])
        channel.confirm_select

        reply_queue = channel.queue('', exclusive: true)

        lock      = Mutex.new
        condition = ConditionVariable.new

        call_id = SecureRandom.uuid

        reply_queue.subscribe do |delivery_info, properties, payload|
          if properties[:correlation_id] == call_id
            response = payload
            lock.synchronize{condition.signal}
          else
            Asynk.logger.error("Message with id: #{message_id} received with error. Waiting for #{call_id} but was #{properties[:correlation_id]}")
          end
        end

        publish_time = Asynk::Benchmark.measure_around do
          exchange.publish(params.to_json, message_id: message_id, routing_key: routing_key, correlation_id: call_id, reply_to: reply_queue.name)
          lock.synchronize{condition.wait(lock, wait_timeout)}
        end

        message = Asynk::Response.try_to_create_from_hash(response)

        if Asynk.config[:publisher_execution_time]
          Asynk.logger.info "Sending sync message to #{routing_key}:#{message_id} with params: #{params}. Completed In: #{publish_time} ms."
        end

        Asynk.logger.debug("Response for #{routing_key}:#{message_id}: #{message.inspect}")

        message
      rescue Celluloid::ConditionError => ex
        Asynk.logger.error "Sending sync message to #{routing_key}:#{message_id} with params: #{params} completed with Timout: #{wait_timeout}"
        raise
      ensure
        reply_queue.delete if reply_queue
        channel.close if channel
      end

      def load_cellulooid
        require 'celluloid'
        require 'celluloid/io'
      end

      def generate_message_id
        SecureRandom.hex(8)
      end
    end
  end
end