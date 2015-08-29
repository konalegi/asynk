require 'time'

module Asynk
  class Logger
    include Singleton

    def debug(msg)
      print_to_stout 'DEBUG', msg
    end

    def info(msg)
      print_to_stout 'INFO', msg
    end

    def warn(msg)
      print_to_stout 'WARN', msg
    end

    def error(msg)
      print_to_stout 'ERROR', msg
    end

    private
      def print_to_stout(level, msg)
        puts "#{level} #{Time.now.strftime('%FT %T.%L')} #{msg}"
      end
  end
end