require File.dirname(__FILE__) + '/jobs/statuses'
require File.dirname(__FILE__) + '/jobs/commands'

module Jobit
  class Jobby < Struct.new(
    :id, :name, :object, :args, :message, :progress, :error, :priority, :run_at,
    :schedule, :repeat, :repeat_delay, :created_at, :started_at, :stopped_at,
    :locked_by, :locked_at, :tries, :status, :keep, :failed_at
  )

    MAX_ATTEMPTS = 25
    MAX_RUN_TIME = 4 # hours

    include Jobit::Jobs::Statuses
    include Jobit::Jobs::Commands

    def initialize(job = nil, options = {})
      if job.nil?
        create_new
        if options
          for key, val in options
            self[key] = val
          end
        end
        self.id = "#{priority}.#{id}"
        Jobit::Storage.create(id, self)
      else
        job.each_with_index do |val, index|
          self[index] = val
        end
      end
    end

    def destroy
      return unless id
      Jobit::Storage.destroy(id)
      clear
    end

    def process_job(args)
      begin
        logger.info "* [JOB:#{name}] acquiring lock"
        runtime = Benchmark.realtime do
          self.status = 'running'
          self.started_at = Time.now.to_f
          update

          self.send("#{object}_task",*args)

          self.status = 'complete'
          self.progress = 100
          self.stopped_at = Time.now.to_f
          update
        end
        logger.info "* [JOB:#{name}]  completed after %.4f" % runtime
      rescue Exception => e
        log_exception(e)
        msg = "#{e.message}\n\n#{e.backtrace.join("\n")}"
        set_error(msg)
      end
    end

    def run_job(worker_name = 'worker')
      return nil if locked?
      lock!(worker_name)
      self.class.send(:include, JobitItems)
      job_args = Marshal.restore(args)
      num = repeat.to_i == 0 ? 1 : repeat.to_i
      delay = repeat_delay.to_i
      num.times do
        process_job(job_args)
        break if failed? # stop loop if job failed
        increase_tries
        sleep delay if delay > 0
      end
      cleanup
    end


    def log_exception(error)
      logger.error "* [JOB:#{name}] failed with #{error.class.name}: #{error.message} - #{tries} failed attempts"
      logger.error(error)
    end

    private

    def logger
      @logger ||= Jobit::Job.logger
    end

    def create_new
      self.id = Time.now.to_f
      self.name = name
      self.message = ''
      self.progress = 0
      self.priority = 0
      self.run_at = id
      self.repeat = 0
      self.repeat_delay = 0
      self.created_at = id
      self.tries = 0
      self.status = 'new'
      self.keep = false
      self
    end

    def reload
      reloaded_job = Storage.find(id)
      reloaded_job.each_with_index do |val, index|
        self[index] = val
      end
    end

    def update
      Jobit::Storage.update(id, self)
    end

    def cleanup
      complete, failed, reissued = 0, 0, 0
      if failed?
        if tries < MAX_ATTEMPTS
          self.tries += 1
          self.run_at = Time.now.to_f + (tries ** 4) + 5
          self.status = 'new'
          unlock!
          update
          reissued = 1
        else
          logger.info "* [JOB:#{name}] Removing... Too many tries."
          destroy unless keep?
          failed = 1
        end
      elsif complete?
        if keep?
          unlock!
        else
          destroy
        end
        complete = 1
      end
      [complete, failed, reissued]
    end

    def clear
      options_size = self.size-1

      for i in (0..options_size)
        self[i]= nil
      end
    end

  end
end