module Jobit
  class Worker
    SLEEP = 5

    def logger
      @logger ||= Jobit::Job.logger
    end

    def initialize(options={})
      @quiet = options[:quiet]
      #Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      #Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
    end

    def start
      #say "*** Starting job worker #{Jobit::Job.worker_name}"
      say "*** Starting job worker #{Jobit::Job.worker_name}"

      trap('TERM') { say 'Exiting...'; $exit = true }
      trap('INT') { say 'Exiting...'; $exit = true }

      loop do
        result = nil

        realtime = Benchmark.realtime do
          result = Jobit::Job.work_off
        end

        count = result.sum

        break if $exit

        if count.zero?
          sleep(SLEEP)
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result[1]]
        end

        break if $exit
      end
    end

    def say(text)
      puts text unless @quiet
      logger.info text if logger
    end

  end
end
