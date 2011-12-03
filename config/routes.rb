Jobit::Engine.routes.draw do
  get '/(:id)', :to => 'jobs#index'
end
