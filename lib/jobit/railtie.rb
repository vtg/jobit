require 'jobit'
require 'rails'
module Jobit
  class Railtie < Rails::Railtie
    railtie_name :jobit

    rake_tasks do
      load "tasks/jobit.rake"
    end
  end
end