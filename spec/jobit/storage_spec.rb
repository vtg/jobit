# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Jobit::Storage do

  def struct
    struct = Struct.new(:id, :name)
    struct.new(@file_name, @job_name)
  end

  before(:each) do
    @file_name = Time.now.to_f
    @job_name = "job#1"
    @total_files = Jobit::Storage.all_files.size
    Jobit::Storage.create(@file_name, struct).should eq(true)
  end

  after(:each) do
    Jobit::Storage.destroy(@file_name)
  end

  after(:all) do
    begin
      Dir.delete(Jobit.jobs_path)
    rescue
      nil
    end
  end

  it "creates file with struct id equal to filename" do
    job = Jobit::Storage.find(@file_name)
    job.should be_a(Struct)
    job.id.should eq(@file_name)
  end

  it ".find returns file value" do
    job = Jobit::Storage.find(@file_name)
    job.should be_a(Struct)
    job.name.should eq(@job_name)
  end

  it ".all retrieves list of jobs" do
    jobs = Jobit::Storage.all
    jobs.should be_a(Array)
    jobs.size.should eq(@total_files+1)
  end


  it ".find_by_name returns file value" do
    job = Jobit::Storage.find_by_name(@job_name)
    job.should be_a(Struct)
    job.name.should eq(@job_name)
  end

  it ".find_by_name with wrong name returns nil" do
    job = Jobit::Storage.find_by_name('wrong_name')
    job.should eq(nil)
  end

  it ".where(name) returns file value" do
    jobs = Jobit::Storage.where(@job_name)
    jobs.should be_a(Array)
    jobs.first.name.should eq(@job_name)
  end

  it ".where(hash) returns file value" do
    jobs = Jobit::Storage.where({:name => @job_name})
    jobs.should be_a(Array)
    jobs.first.name.should eq(@job_name)
  end

  it ".where(wrong hash key) returns empty array" do
    jobs = Jobit::Storage.where({:name1 => @job_name})
    jobs.should be_a(Array)
    jobs.size.should eq(0)
  end

  it ".where(wrong hash value) returns empty array" do
    jobs = Jobit::Storage.where({:name => 'wrong_name'})
    jobs.should be_a(Array)
    jobs.size.should eq(0)
  end

  it "find by name and update" do
    job = Jobit::Storage.find_by_name(@job_name)
    job.name = "new name"
    Jobit::Storage.update(job.id, job)
    job = Jobit::Storage.find(job.id)
    job.should be_a(Struct)
    job.name.should eq('new name')
  end

end