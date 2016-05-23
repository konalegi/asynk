module Asynk
  class Config
    include Singleton
    def initialize
      @params = {
                      mq_exchange: 'asynk_exchange_topic',
        sync_publish_wait_timeout: 10,
     default_consumer_concurrency: 1,
                     default_sync: false,
                        daemonize: false,
                          logfile: 'log/asynk.log',
                          pidifle: 'tmp/pids/asynk.pid',
                          mq_host: 'localhost',
                          mq_port: 5672,
                         mq_vhost: '/',
                      mq_username: 'guest',
                      mq_password: 'guest',
          publisher_execution_time: true,
       respond_back_execution_time: true,
                ignored_consumers: []
      }
    end

    def [](key)
      @params[key]
    end

    def []=(key, value)
      @params[key] = value
    end

  end
end
