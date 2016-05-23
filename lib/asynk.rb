require 'connection_pool'
require 'singleton'
require 'securerandom'
require 'bunny'
require 'active_support'
require 'asynk/config'
require 'asynk/publisher'
require 'asynk/broker'
require 'asynk/consumer'
require 'asynk/logging'
require 'asynk/server'
require 'asynk/message'
require 'asynk/response'
require 'asynk/benchmark'
require 'asynk/sync_publisher'
require 'asynk/test_helper'

module Asynk

  DEFAULTS = {
    require: '.',
    environment: nil
  }

  class << self
    def register_consumer(consumer)
      return if Asynk.config[:ignored_consumers].include? consumer.name
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
      Asynk::Logging.logger
    end

    def logger=(log)
      Asynk::Logging.logger = log
    end

    def server
      Server.instance
    end

    def broker; Broker; end

    def booted_inside?; @booted_inside; end

    def booted_inside=(value)
      @booted_inside = value
    end

    def config; Config.instance; end
  end
end
