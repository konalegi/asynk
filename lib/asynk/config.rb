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
        pidifle: 'tmp/pids/asynk.pid'
      }
    end

    def [](key)
      @params[key]
    end

  end
end