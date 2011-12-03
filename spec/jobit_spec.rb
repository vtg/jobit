# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

module JobitItems

  def good_job(opt1, opt2)
    set_progress(10)
    unless opt1 == 'val1'
      raise(NoMethodError, 'wrong arguments 0')
    end
    unless opt2 == 'val2'
      raise(NoMethodError, 'wrong arguments 1')
    end
    set_progress(100)
  end

  def bad_job(text)
    add_message "start"
    set_progress(10)
    add_message "end"
    raise(NoMethodError, "Some dumb error #{text}")
  end
end

describe Jobit do
  describe "Job" do

    before(:each) do
      @job_name = 'job-1'
      @total_jobs = Jobit::Job.all.size
      @new_job = Jobit::Job.add(@job_name, :good_job, 'val1', 'val2') {
        {:priority => 1}
      }
    end

    after(:each) do
      @new_job.destroy
    end

    after(:all) do
      begin
        Dir.delete(Jobit::JOBS_PATH)
      rescue
        nil
      end
    end

    it "creates new job" do
      @new_job.name.should eq(@job_name)
    end

    it 'returns nil if not found' do
      job = Jobit::Job.find('123')
      job.should eq(nil)
    end

    it 'returns job if found by id' do
      job = Jobit::Job.find(@new_job.id)
      job.name.should eq(@job_name)
    end

    it 'returns job if found_by_name' do
      job = Jobit::Job.find_by_name(@job_name)
      job.name.should eq(@job_name)
    end

    it 'returns array of all jobs' do
      jobs = Jobit::Job.all
      jobs.should be_a(Array)
      jobs.size.should eq(@total_jobs+1)
      jobs.first.name.should be_a(String)
    end

    it 'returns array of found jobs' do
      jobs = Jobit::Job.where(:name => @job_name)
      jobs.should be_a(Array)
      jobs.size.should eq(1)
      jobs.first.name.should eq(@job_name)
    end

    it 'returns empty array if wrong key' do
      jobs = Jobit::Job.where(:name1 => @job_name)
      jobs.should be_a(Array)
      jobs.size.should eq(0)
    end

    it 'returns empty array if wrong value' do
      jobs = Jobit::Job.where(:name => 'wrong name')
      jobs.should be_a(Array)
      jobs.size.should eq(0)
    end

    it 'destroys job' do
      @new_job.destroy
      job = Jobit::Job.find_by_name(@job_name)
      job.should eq(nil)
    end

    it 'update status' do
      @new_job.status.should eq('new')
      @new_job.set_status 'running'
      @new_job.status.should eq('running')
      job = Jobit::Job.find_by_name(@job_name)
      job.status.should eq('running')
    end

    it 'update error' do
      @new_job.error.should eq(nil)
      @new_job.set_error 'my error'
      @new_job.error.should eq('my error')
      job = Jobit::Job.find_by_name(@job_name)
      job.error.should eq('my error')
    end

    it 'update error' do
      @new_job.tries.should eq(0)
      @new_job.set_tries 1
      @new_job.tries.should eq(1)
      job = Jobit::Job.find_by_name(@job_name)
      job.tries.should eq(1)
    end

    it 'update progress' do
      @new_job.progress.should eq(0)
      @new_job.set_progress 10
      @new_job.progress.should eq(10)
      job = Jobit::Job.find_by_name(@job_name)
      job.progress.should eq(10)
    end

    it 'adds message' do
      @new_job.message.should eq('')
      @new_job.add_message('hello',true)
      @new_job.message.should eq('hello')
      job = Jobit::Job.find_by_name(@job_name)
      job.message.should eq('hello')
      @new_job.add_message(' there',true)
      @new_job.message.should eq('hello there')
      job = Jobit::Job.find_by_name(@job_name)
      job.message.should eq('hello there')
    end

    it 'running good job' do
      @new_job.run_job
      job = Jobit::Job.find_by_name(@job_name)
      job.should eq(nil)
    end

    it 'running good job 5 times' do
      job = Jobit::Job.add('good_job', :good_job, 'val1', 'val2') { {
        :priority => 0,
        :repeat => 5
      } }
      job.keep?.should eq(false)
      job.run_job
      job = Jobit::Job.find_by_name('good_job')
      job.should eq(nil)
    end

    it 'running good job 5 times and keep file' do
      job = Jobit::Job.add('good_job_keep', :good_job, 'val1', 'val2') { {
        :priority => 0,
        :repeat => 5,
        :keep => true
      } }
      job.run_job
      job = Jobit::Job.find_by_name('good_job_keep')
      job.tries.should eq(5)
      job.run_at.should_not eq(nil)
      job.destroy
    end

    it 'running bad job' do
      job = Jobit::Job.add('bad_job', :bad_job, 'val1') {
        {
          :priority => 0,
          :keep => true
        }
      }

      job.run_job
      job = Jobit::Job.find_by_name('bad_job')
      job.tries.should eq(1)
      job.message.should eq('startend')
      job.status.should eq('new')
      job.progress.should eq(10)
      job.destroy
    end

    it 'running bad job 5 times should run it just once' do
      job = Jobit::Job.add('bad_job_5', :bad_job, 'val1') {
        {
          :priority => 0,
          :repeat => 5
        }
      }

      job.run_job
      job = Jobit::Job.find_by_name('bad_job_5')
      job.tries.should eq(1)
      job.status.should eq('new')
      job.progress.should eq(10)
      job.destroy
    end

    it 'work_off test' do
      @new_job.destroy
      for i in (0..5)
        Jobit::Job.add("work_off_#{i}", :good_job, 'val1', 'val2') { {
          :priority => rand(6),
          :keep => true
        } }
      end
      Jobit::Job.add('work_off_bad', :bad_job, 'val1') { {
        :priority => 2,
        :keep => true
      } }

      Jobit::Job.work_off
      jobs = []
      for i in (0..5)
        job = Jobit::Job.find_by_name("work_off_#{i}")
        job.status.should eq('complete'), " #{job}"
        job.destroy
        job.id.should eq(nil)
      end

      job_failed = Jobit::Job.find_by_name('work_off_bad')
      job_failed.tries.should eq(25)
      job_failed.status.should eq('failed')
      job_failed.destroy

    end

  end
end