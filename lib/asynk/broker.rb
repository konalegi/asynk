# require 'carrot-top'

module Asynk
  class Broker
    class << self
      def connect
        @amqp_connection = Bunny.new(host: Asynk.config[:mq_host],
                                     port: Asynk.config[:mq_port],
                                 username: Asynk.config[:mq_username],
                                 password: Asynk.config[:mq_password],
                                    vhost: Asynk.config[:mq_vhost])
        Asynk.logger.info [ "Connection to Rabbit with params host: #{Asynk.config[:mq_host]}:#{Asynk.config[:mq_port]}",
                            "username: '#{Asynk.config[:mq_username]}' ", "vhost: '#{Asynk.config[:mq_vhost]}'"
                          ].join(' ')

        @amqp_connection.start

        @pool = ConnectionPool.new(size: 10, timeout: 5) do
          channel = @amqp_connection.create_channel(nil, nil)
          [channel, channel.topic(Asynk.config[:mq_exchange]), channel.queue('', exclusive: true)]
        end
      end

      def disconnect
        @amqp_connection.close if @amqp_connection
        @amqp_connection = nil
      end

      def pool; @pool; end
      def amqp_connection; @amqp_connection; end
    end
  end
end
