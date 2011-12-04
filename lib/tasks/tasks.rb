# Re-definitions are appended to existing tasks
task :environment

namespace :jobit do
  desc "Clear the Jobit job queue."
  task :clear => :environment do
    Jobit::Job.destroy_all
  end

  desc "Clear the Jobit filed jobs."
  task :clear_failed => :environment do
    Jobit::Job.destroy_failed
  end

  desc "Start a Jobit worker."
  task :work => :environment do
    Jobit::Worker.new().start
  end
end