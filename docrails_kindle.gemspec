# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "docrails_kindle"
  s.version     = '0.0.5'
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.0'

  s.authors     = ["Daniel Choi"]
  s.email       = ["dhchoi@gmail.com"]
  s.homepage    = "http://github.com/danchoi/docrails_kindle"
  s.summary     = %q{Read Rails Guides on your Kindle}
  s.description = %q{Read Rails Guides on your Kindle}

  s.rubyforge_project = "docrails_kindle"

  s.files         = `git ls-files`.split("\n").select {|x| x !~ /gif|mobi$/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'nokogiri'
  s.add_dependency 'kindlerb'
end
