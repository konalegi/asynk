module Asynk
  DEFAULTS = {
    require: '.',
    environment: nil
  }

  class << self
    def options
      @options ||= DEFAULTS.dup
    end

    def options=(opts)
      @options = opts
    end
  end
end