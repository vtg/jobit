require 'logger'
require 'benchmark'

module Jobit

  class Job

    def self.jobs_path
      if defined?(Rails)
        "#{Rails.root.to_s}/tmp/jobit"
      else
        "/tmp/jobit"
      end
    end

    def self.worker_name
      "host:#{Socket.gethostname} pid:#{Process.pid}" rescue "pid:#{Process.pid}"
    end

    def self.destroy_all
      Storage.destroy_all
    end

    def self.destroy_failed
      failed_jobs = Storage.where({:status => 'failed'})
      for job in failed_jobs
        job.destroy
      end
      true
    end

    def self.logger
      if defined?(Rails)
        Logger.new("#{Rails.root.to_s}/log/jobit.log", shift_age = 7, shift_size = 1048576)
      else
        Logger.new(File.dirname(__FILE__) + "/../../log/jobit.log")
      end
    end

    # Jobit::Job.all
    # returns array of all jobs
    def self.all
      Storage.all
    end

    # Jobit::Job.find(11111.111)
    # returns job or nil
    def self.find(id)
      Storage.find(id)
    end

    # Jobit::Job.find_by_name('name')
    # returns job or nil
    def self.find_by_name(name)
      Storage.find_by_name(name)
    end

    # Jobit::Job.where({:name => 'name'})
    # returns array of found jobs
    def self.where(search)
      Storage.where(search)
    end

    # Jobit::Job.add(name, object, *args) {{options}}
    # options:
    #   :priority => the job priority (Integer)
    #   :run_after => run job after some time from now ex: :run_after => 4.hours
    #   :schedule => run job at some time. ex: :schedule_at => "16:00"
    #   :repeat => how many times to repeat the job (Integer)
    #   :repeat_delay => delay in seconds before next repeat
    def self.add(name, object, *args, &block)
      unless JobitItems.method_defined?(object)
        raise ArgumentError, "Can't add job #{object}. It's not defined in jobs."
      end

      options = {}
      options = yield if block_given?

      options[:name] = name
      options[:object] = object
      options[:args] = Marshal.dump(args)

      Jobby.new(nil, options)
    end

    def self.work_off(num = 100)
      complete, failed, reissued = 0, 0, 0
      num.times do
        jobs = self.where({:status => 'new'})
        break unless jobs.size > 0
        res = jobs.first.run_job
        complete += res[0]
        failed += res[1]
        reissued += res[2]
        break if $exit
      end
      [complete, failed, reissued]
    end

  end

end
