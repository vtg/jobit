require 'rubygems'
require 'daemons'
require 'optparse'

module Jobit
  class Command
    attr_accessor :worker_count

    def initialize(args)
      @files_to_reopen = []
      @options = {
        :quiet => true,
        :pid_dir => "#{Rails.root}/tmp/pids"
      }

      @worker_count = 1
      @monitor = false

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-n', '--number_of_workers=workers', "Number of unique workers to spawn") do |worker_count|
          @worker_count = worker_count.to_i rescue 1
        end
      end
      @args = opts.parse!(args)
    end

    def daemonize
      #Jobit::Worker.backend.before_fork

      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end

      dir = @options[:pid_dir]
      Dir.mkdir(dir) unless File.exists?(dir)

      if @worker_count > 1 && @options[:identifier]
        raise ArgumentError, 'Cannot specify both --number-of-workers and --identifier'
      elsif @worker_count == 1 && @options[:identifier]
        process_name = "jobit.#{@options[:identifier]}"
        run_process(process_name, dir)
      else
        worker_count.times do |worker_index|
          process_name = worker_count == 1 ? "jobit" : "jobit.#{worker_index}"
          run_process(process_name, dir)
        end
      end
    end

    def run_process(process_name, dir)
      Daemons.run_proc(process_name, :dir => dir, :dir_mode => :normal, :monitor => @monitor, :ARGV => @args) do |*args|
        $0 = File.join(@options[:prefix], process_name) if @options[:prefix]
        run process_name
      end
    end

    def run(worker_name = nil)

      begin
        # releasing connection if started in production environment with caching enabled
        ActiveRecord::Base.connection_pool.release_connection
      rescue ::Exception
      end

      Dir.chdir(Rails.root)

      # Re-open file handles
      @files_to_reopen.each do |file|
        begin
          file.reopen file.path, "a+"
          file.sync = true
        rescue ::Exception
        end
      end

      #Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
      #Delayed::Worker.backend.after_fork

      worker = Jobit::Worker.new(@options)
      #worker.name_prefix = "#{worker_name} "
      worker.start
    rescue => e
      Rails.logger.fatal e
      STDERR.puts e.message
      exit 1
    end

  end
end
