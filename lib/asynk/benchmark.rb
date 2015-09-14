module Asynk
  class Benchmark
    class << self
      def measure_around(message, &block)
        start_time = Time.now.to_f
        block.call
      ensure
        Asynk.logger.debug "#{message}. Completed In: #{((Time.now.to_f - start_time)*1000).round(2)} ms."
      end
    end
  end
end