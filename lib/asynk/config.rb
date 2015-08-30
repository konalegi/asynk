module Asynk
  class Config
    include Singleton
    def initialize
      @params = {
        mq_exchange: 'asynk_exchange_topic',
        sync_publish_wait_timeout: 10
      }
    end

    def [](key)
      @params[key]
    end

  end
end