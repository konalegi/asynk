module Asynk
  class Config
    include Singleton
    def initialize
      @params = {
        mq_exchange: 'asynk_exchange_topic'
      }
    end

    def [](key)
      @params[key]
    end

  end
end