require 'jmx'

class JMXExamples
  def self.server(*args)
    @server ||= if args.length > 0
      JMX.connect(*args)
    else
      JMX::MBeanServer.new
    end
  end

  def self.memory_bean
    @memory_bean ||= server["java.lang:type=Memory"]
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

  class MemorySampler
    def initialize(&block)
      @samples = []
      @keep = 50
      @interval = 2
      @callback = block
    end

    def samples
      dat = @samples.dup.transpose
      { "Heap" => dat.first, "Non-Heap" => dat.last }
    end

    def start
      @thread = Thread.new do
        while true do
          @samples << JMXExamples.memory_usage.map {|m| m.to_f / (1024*1024) }
          @samples.shift if @samples.size > @keep
          @callback.call(self) if @callback
          sleep @interval
        end
      end
      @thread.join
    end
  end
end
