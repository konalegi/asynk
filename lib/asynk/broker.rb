# require 'carrot-top'

module Asynk
  class Broker
    # include Singleton

    # def initialize
    # end
    class << self
      def amqp_connection
        @amqp_connection ||= begin
          conn = Bunny.new(host: Asynk.config[:mq_host],
                           port: Asynk.config[:mq_port],
                       username: Asynk.config[:mq_username],
                       password: Asynk.config[:mq_password],
                          vhost: Asynk.config[:mq_vhost])
          p conn
          conn.start
          conn
        end
      end
    end

  end
end
