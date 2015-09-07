# require 'carrot-top'

module Asynk
  class Broker
    class << self
      def amqp_connection
        @amqp_connection ||= begin
          conn = Bunny.new(host: Asynk.config[:mq_host],
                           port: Asynk.config[:mq_port],
                       username: Asynk.config[:mq_username],
                       password: Asynk.config[:mq_password],
                          vhost: Asynk.config[:mq_vhost])
          Asynk.logger.info [ "Connection to Rabbit with params host: #{Asynk.config[:mq_host]}:#{Asynk.config[:mq_port]}",
                              "username: '#{Asynk.config[:mq_username]}', password: '#{Asynk.config[:mq_password]}'",
                              "vhost: '#{Asynk.config[:mq_vhost]}'"
                            ].join(' ')
          conn.start
          conn
        end
      end

      def pubisher_channel_pool
        @connection_pool ||= ConnectionPool.new(size: 5, timeout: 10){ Asynk.broker.amqp_connection.create_channel }
      end
    end

  end
end
