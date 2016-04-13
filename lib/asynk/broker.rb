# require 'carrot-top'

module Asynk
  class Broker
    class << self
      def connect
        @amqp_connection ||= begin
          conn = Bunny.new(host: Asynk.config[:mq_host],
                           port: Asynk.config[:mq_port],
                       username: Asynk.config[:mq_username],
                       password: Asynk.config[:mq_password],
                          vhost: Asynk.config[:mq_vhost])
          Asynk.logger.info [ "Connection to Rabbit with params host: #{Asynk.config[:mq_host]}:#{Asynk.config[:mq_port]}",
                              "username: '#{Asynk.config[:mq_username]}' ", "vhost: '#{Asynk.config[:mq_vhost]}'"
                            ].join(' ')
          conn.start
          conn
        end
      end

      def disconnect
        @amqp_connection.close if @amqp_connection
        @amqp_connection = nil
      end

      def amqp_connection; @amqp_connection; end
    end
  end
end
