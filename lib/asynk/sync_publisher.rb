module Asynk
  class SyncPublisher
    def initialize(routing_key, params)
      @routing_key    = routing_key
      @params         = params
      @message_id     = (@params.delete(:message_id) || generate_message_id)
      @wait_timeout   = (@params.delete(:timeout) || Asynk.config[:sync_publish_wait_timeout]) * 1000
      @correlation_id = generate_message_id
    end

    def send
      global_start_time = Asynk::Benchmark.start if Asynk.config[:publisher_execution_time]
      Asynk.broker.pool.with do |channel, exchange, reply_queue|
        exchange.publish(@params.to_json, message_id: @message_id, routing_key: @routing_key, correlation_id: @correlation_id, reply_to: reply_queue.name)

        start_time = Asynk::Benchmark.start
        while !@response do
          delivery_info, properties, payload = reply_queue.pop
          @response = payload if payload && properties[:correlation_id] == @correlation_id
          raise(RuntimeError.new('Timeout error reached')) if @wait_timeout <= Asynk::Benchmark.end(start_time)
        end
      end

      message = Asynk::Response.try_to_create_from_hash(@response)
      if Asynk.config[:publisher_execution_time]
        Asynk.logger.info "Sending sync message to #{@routing_key}:#{@message_id}. Completed In: #{Asynk::Benchmark.end(global_start_time)} ms."
      end

      message
    end

    def generate_message_id(legnth = 8)
      SecureRandom.hex(legnth)
    end
  end
end
