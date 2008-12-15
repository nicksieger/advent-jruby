%w(gruff rmagick4j jmx).each do |g|
  begin
    gem g
  rescue Gem::LoadError
    $LOAD_PATH.unshift File.expand_path(FileList['vendor/*/lib'].detect {|f| f =~ /#{g}/i})
  end
end
$LOAD_PATH.unshift File.expand_path("lib")

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

  desc "Simple JMX memory monitoring example: print memory usage"
  task :memory => :connect do
    JMXExamples.print_memory_usage
  end

  desc "Gruff/JMX example plotting memory usage over time"
  task :tracker => :connect do
    require 'rubyadvent/gruffexamples'
    GruffExamples.memory_tracker
  end
end

desc "Run IRB with Gruff, RMagick4J and JMX loaded"
task :irb do
  ARGV.clear; ARGV << '--simple-prompt'
  require 'irb'
  require 'rubyadvent/gruffexamples'
  require 'rubyadvent/jmxexamples'
  IRB.start(__FILE__)
end

task :default do
  puts "To run an example, re-run 'jruby -S rake' with one of the following tasks:"
  class << Rake.application; public :display_tasks_and_comments; end
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end
