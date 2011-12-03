module Jobit
  module Jobs
    module Commands
      def set_start_time
        self.started_at = Time.now.to_f
        update
      end

      def set_stop_time
        self.stopped_at = Time.now.to_f
        update
      end

      def set_status(new_status)
        self.status = new_status
        update
      end

      def set_error(text)
        self.error = text
        self.status = 'failed'
        self.stopped_at = Time.now.to_f
        self.failed_at = stopped_at
        update
      end

      def set_tries(num)
        self.tries = num
        update
      end

      def increase_tries
        self.tries += 1
        update
      end

      def set_progress(num)
        self.progress = num
        update
      end

      def add_message(text, force = false)
        if self.keep? || force
          self.message += text
          update
        end
      end

      def unlock!
        self.locked_at= nil
        self.locked_by= nil
        update
      end

      def lock!(worker_name)
        self.run_at= Time.now.to_f
        self.locked_at= Time.now.to_f
        self.locked_by= worker_name
        update
      end

    end
  end
end