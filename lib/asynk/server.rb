module Asynk
  class Server
    include Singleton

    def initialize
    end

    def run
      prepare_consumers
      register_signal_handlers
      Asynk.logger.info "All consumers are prepared"
      handle_signals
      # handle_signals
    end

    def shutdown
      futures = workers.map { |w| w.future.shutdown }
      futures.map(&:value)
      Asynk.broker.amqp_connection.close
      Asynk.logger.info "Server shutdown!"
    end

    private
      def handle_signals
        loop do
          signal = Thread.main[:signal_queue].shift
          if signal
            Asynk.logger.info "Caught sig#{signal.downcase}, stopping asynk server..."
            shutdown
            break
          end
          sleep(0.1)
        end
      end

      def workers
        @workers ||= []
      end

      def register_signal_handlers
        Thread.main[:signal_queue] = []
        %w(QUIT TERM INT).keep_if { |s| Signal.list.keys.include? s }.map(&:to_sym).each do |sig|
          # This needs to be reentrant, so we queue up signals to be handled
          # in the run loop, rather than acting on signals here
          trap(sig) do
            Thread.main[:signal_queue] << sig
          end
        end
      end

      def prepare_consumers
        Asynk.consumers.each{ |consumer| prepare_consumer(consumer) }
      end

      def prepare_consumer(consumer)
        consumer.concurrency.times do |index|
          workers << Asynk::Worker.new(Asynk.broker.amqp_connection, consumer, index)
        end
      end
  end
end