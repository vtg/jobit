module Jobit
  module Jobs
    module Statuses
      def running?
        status == 'running'
      end

      def failed?
        status == 'failed'
      end

      def complete?
        status == 'complete'
      end

      def stopped?
        status == 'stopped'
      end

      def new?
        status == 'new'
      end

      def keep?
        keep
      end

      def locked?
        locked_at != nil
      end

      def current_job
        self
      end

      def session
        {
          :name => name,
          :message => message,
          :progress => progress,
          :error => error,
          :run_at => run_at,
          :created_at => created_at,
          :started_at => started_at,
          :stopped_at =>stopped_at,
          :tries => tries,
          :status => status,
          :failed_at => failed_at
        }
      end

      def time_to_run?
        if tries == 0
          Time.now.to_f >= run_at.to_f
        else
          true
        end
      end
    end
  end
end