require 'bundler'
Bundler.setup

require "rspec"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "zwaveascii/version"

desc "Builds the gem"
task :gem => :build
task :build do
  system "gem1.9 build zwaveascii.gemspec"
  Dir.mkdir("pkg") unless Dir.exists?("pkg")
  system "mv zwaveascii-#{ZWave::ASCII::VERSION}.gem pkg/"
end

task :install => :build do
  system "sudo gem1.9 install pkg/zwaveascii-#{ZWave::ASCII::VERSION}.gem"
end

desc "Release the gem - Gemcutter"
task :release => :build do
  system "git tag -a v#{ZWave::ASCII::VERSION} -m 'Tagging #{ZWave::ASCII::VERSION}'"
  system "git push --tags"
  system "gem push pkg/zwaveascii-#{ZWave::ASCII::VERSION}.gem"
end

task :default => [:spec]
