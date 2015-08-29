# require 'carrot-top'

module Asynk
  class Broker
    # include Singleton

    # def initialize
    # end
    class << self
      def amqp_connection
        @amqp_connection ||= begin
          conn = Bunny.new
          conn.start
          conn
        end
      end
    end

  end
end
