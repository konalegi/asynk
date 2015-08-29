$stdout.sync = true

require 'optparse'
require 'fileutils'
require 'singleton'
require 'asynk'
module Asynk
  class CLI
    include Singleton
    attr_accessor :environment

    def run(args=ARGV)
      setup_options(args)
      boot_system
      Asynk.server.run
    end

    private
      def options
        Asynk.options
      end

      def setup_options(args)
        opts = parse_options(args)
        set_environment opts[:environment]
        options.merge!(opts)
      end

      def boot_system
        Asynk.logger.info 'Booting rails app'
        ENV['RACK_ENV'] = ENV['RAILS_ENV'] = environment

        raise ArgumentError, "#{options[:require]} does not exist" unless File.exist?(options[:require])

        if File.directory?(options[:require])
          require File.expand_path("#{options[:require]}/config/application.rb")
          require File.expand_path("#{options[:require]}/config/environment.rb")
          ::Rails.application.eager_load!
        else
          require options[:require]
        end
      end

      def set_environment(cli_env)
        @environment = cli_env || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end

      def parse_options(argv)
        opts = {}

        @parser = OptionParser.new do |o|
          o.on '-d', '--daemon', "Daemonize process" do |arg|
            opts[:daemon] = arg
          end

          o.on '-e', '--environment ENV', "Application environment" do |arg|
            opts[:environment] = arg
          end

          o.on '-r', '--require [PATH|DIR]', "Location of Rails application with workers or file to require" do |arg|
            opts[:require] = arg
          end

          o.on '-L', '--logfile PATH', "path to writable logfile" do |arg|
            opts[:logfile] = arg
          end

          o.on '-P', '--pidfile PATH', "path to pidfile" do |arg|
            opts[:pidfile] = arg
          end

          o.on '-V', '--version', "Print version and exit" do |arg|
            puts "Sidekiq #{Sidekiq::VERSION}"
            die(0)
          end
        end

        @parser.parse!(argv)
        # opts[:config_file] ||= 'config/sidekiq.yml' if File.exist?('config/sidekiq.yml')
        opts
      end
  end
end