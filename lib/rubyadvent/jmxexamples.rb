require 'jmx'

class JMXExamples
  def self.client
    @client ||= JMX::MBeanServer.new
  end

  def self.memory_bean
    @memory_bean ||= client["java.lang:type=Memory"]
  end

  def self.in_mb(value)
    format "%0.2f MB" % (value.to_f / (1024 * 1024))
  end

  def self.memory_usage
    [memory_bean.heap_memory_usage.used, memory_bean.non_heap_memory_usage.used]
  end

  def self.print_memory_usage
    heap, non_heap = memory_usage
    puts "Heap: #{in_mb(heap)}, Non-Heap: #{in_mb(non_heap)}"
  end

  def self.print_jruby_config
    
  end
end
