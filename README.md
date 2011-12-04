# Jobit [![Build Status](https://secure.travis-ci.org/vtg/jobit.png)](http://travis-ci.org/vtg/jobit)

Jobit helps to manage background jobs processing with job status and progress monitoring.

## Installation

Add to your Gemfile and run the `bundle` command to install it.

```ruby
gem "jobit"
```

**Requires Ruby 1.9.2 or later.**


## Usage

Create jobs file app/model/jobit_items.rb and put your tasks there:

```ruby
method JobitItems

  def some_long_running_task_without_response(arg)
    sleep 60
  end

  def some_long_running_task_with_response(arg1, arg2)
    add_message("job #{name} started\n")
    set_progress(10)
    sleep 60
    set_progress(80)
    add_message("job #{name} half complete\n")
    sleep 10
    add_message("job #{name} complete\n")
  end

end
```

###Running worker to process the jobs queue

```ruby
rake jobit:work
```


###Adding jobs to queue

```ruby
#job will be added to queue and processed. After successful processing it will be destroyed
new_job = Jobit::Job.add("job_name", :some_long_running_task_without_response, 'val1')

#job will be added to queue and processed. After processing it wont be destroyed so you can see its messages and progress
new_job = Jobit::Job.add("job_name", :some_long_running_task_with_response, 'val1', 'val2'){{ :keep => true }}
```

###Monitoring job progress and responses

```ruby
#returns nil if job not in queue
job = Jobit::Job.find_by_name('job_name')

job.status #current job status
job.message #job responses in defined in job
job.progress #job progress
job.error #job error if status is "failed"
```

###Monitoring job progress from your rails application

in routes.rb add:

```ruby
mount Jobit::Engine => "/jobs"
```

now in your can see the status of job in your browser

```ruby
http://127.0.0.1:3000/jobs/job_name
```
It will return the job with name "job_name" in json format


##Cleaning jobs

```ruby
rake jobit:clear # destroying all jobs in the queue.
rake jobit:clear_failed # destroying only failed jobs in the queue.
```

*More details coming soon*


