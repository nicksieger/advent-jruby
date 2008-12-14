FileList['lib', 'vendor/*/lib'].each {|d| $LOAD_PATH.unshift File.expand_path(d) }

namespace :gruff do
  desc "Simple Gruff example with JRuby"
  task :simple do
    require 'rubyadvent/gruffexamples'
    GruffExamples.simple
  end
end

namespace :jmx do
  task :connect do
    require 'rubyadvent/jmxexamples'
    options = {}
    options[:user]     = ENV['jmxuser']     if ENV['jmxuser']
    options[:password] = ENV['jmxpassword'] if ENV['jmxpassword']
    options[:host]     = ENV['jmxhost']     if ENV['jmxhost']
    JMXExamples.server(options) unless options.empty?
  end

  desc "Simple JMX memory monitoring example"
  task :simple => :connect do
    JMXExamples.print_memory_usage
  end

  desc "Gruff/JMX example plotting memory usage over time"
  task :memory => :connect do
    require 'rubyadvent/gruffexamples'
    GruffExamples.memory_visualizer
  end
end

task :irb do
  ARGV.clear
  require 'irb'
  IRB.start(__FILE__)
end
