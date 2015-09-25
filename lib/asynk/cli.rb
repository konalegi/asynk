$stdout.sync = true

require 'optparse'
require 'fileutils'
require 'asynk'
module Asynk
  class CLI
    include Singleton
    attr_accessor :environment

    def run(args=ARGV)
      Asynk.booted_inside = true
      setup_options(args)
      boot_system
      daemonize
      load_celluloid
      write_pid
      Asynk.server.run
    end

    private

      def load_celluloid
        raise "Celluloid cannot be required until here, or it will break Sidekiq's daemonization" if defined?(::Celluloid) && options[:daemon]

        # Celluloid can't be loaded until after we've daemonized
        # because it spins up threads and creates locks which get
        # into a very bad state if forked.
        require 'celluloid'
        require 'celluloid/io'
        Celluloid.logger = (options[:verbose] ? Asynk.logger : nil)
      end

      def daemonize
        return unless options[:daemon]

        raise ArgumentError, "You really should set a logfile if you're going to daemonize" unless options[:logfile]
        files_to_reopen = []
        ObjectSpace.each_object(File) do |file|
          files_to_reopen << file unless file.closed?
        end

        ::Process.daemon(true, true)

        files_to_reopen.each do |file|
          begin
            file.reopen file.path, "a+"
            file.sync = true
          rescue ::Exception
          end
        end

        [$stdout, $stderr].each do |io|
          File.open(options[:logfile], 'ab') do |f|
            io.reopen(f)
          end
          io.sync = true
        end
        $stdin.reopen('/dev/null')

        initialize_logger
      end

      def write_pid
        if path = options[:pidfile]
          pidfile = File.expand_path(path)
          File.open(pidfile, 'w') do |f|
            f.puts ::Process.pid
          end
        end
      end

      def options
        Asynk.options
      end

      def initialize_logger
        Asynk::Logging.initialize_logger(options[:logfile]) if options[:logfile]
        Asynk.logger.level = ::Logger::DEBUG if options[:verbose]
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
            puts "Asynk #{Asynk::VERSION}"
            exit(0)
          end

          o.on "-v", "--verbose", "Print more verbose output" do |arg|
            opts[:verbose] = arg
          end
        end

        @parser.parse!(argv)
        opts
      end
  end
end