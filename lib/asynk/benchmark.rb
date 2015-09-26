module Asynk
  class Benchmark
    class << self
      def measure_around(&block)
        start_time = Time.now.to_f
        block.call
        ((Time.now.to_f - start_time)*1000).round(2)
      end
    end
  end
end