require 'singleton'
require 'securerandom'
require 'celluloid'
require 'celluloid/io'
require 'bunny'
require 'asynk/config'
require 'asynk/publisher'
require 'asynk/broker'
require 'asynk/consumer'
require 'asynk/logger'
require 'asynk/server'
require 'asynk/worker'
require 'asynk/message'

module Asynk
  DEFAULTS = {
    require: '.',
    environment: nil
  }

  class << self
    def register_consumer(consumer)
      self.consumers << consumer
    end

    def consumers
      @consumers ||= []
    end

    def options
      @options ||= DEFAULTS.dup
    end

    def options=(opts)
      @options = opts
    end

    def logger
      Logger.instance
    end

    def server
      Server.instance
    end

    def broker
      Broker
    end

    def config
      Config.instance
    end
  end
end