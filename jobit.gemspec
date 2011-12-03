# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jobit/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Victor Yunevich"]
  gem.email         = ["v.t.g.m.b.x@gmail.com"]
  gem.description   = %q{Process background jobs in queue.}
  gem.summary       = %q{Background jobs processing}
  gem.homepage      = "http://github.com/vtg/jobit"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "jobit"
  gem.require_paths = ["lib"]
  gem.version       = Jobit::VERSION
  
  gem.add_dependency "daemons"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
