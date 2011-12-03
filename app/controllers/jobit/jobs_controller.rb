module Jobit
  class JobsController < ActionController::Base

    def index
      job = Jobit::Job.find_by_name(params[:id])

      if job.nil?
        json_response = {:status => 'not_found'}
      else
        json_response = job.session
        if job.status == 'complete'
          job.destroy if job.status == "complete"
        end
      end

      render :json => json_response
    end
  end
end