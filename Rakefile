FileList['lib', 'vendor/*/lib'].each {|d| $LOAD_PATH.unshift File.expand_path(d) }

namespace :gruff do
  desc "Simple Gruff example with JRuby"
  task :simple do
    require 'rubyadvent/gruffexamples'
    GruffExamples.simple
  end
end

namespace :jmx do
  desc "Simple JMX memory monitoring example"
  task :simple do
    require 'rubyadvent/jmxexamples'
    JMXExamples.print_memory_usage
  end

  task :memory do
    require 'rubyadvent/gruffexamples'
    require 'rubyadvent/jmxexamples'
    GruffExamples.memory_visualizer
  end
end

task :irb => :requires do
  ARGV.clear
  require 'irb'
  IRB.start(__FILE__)
end
