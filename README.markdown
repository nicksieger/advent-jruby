In this installment of the Ruby Advent Calendar 2008, I'll show you
how easy it is to use JRuby to mix and match both Ruby and Java tools
to quickly create a simple memory monitoring program.

We'll be using the venerable [Gruff graphing library][1], along with
[RMagick4J][2], a Java port of the ImageMagick/RMagick imaging library
for JRuby, and the [jmx gem][3] as a nice Ruby wrapper around Java's
JMX (Java Management Extensions) apis.

If you already have a JRuby installation you'd like to use to play
around with the code for this article, you can install the gems we
need as follows:

    jruby -S gem install gruff rmagick4j jmx

(If you haven't played with JRuby before or don't have an install
handy, a [bundle is available][4] of the code for this
article, including JRuby and all dependencies.)

## Gruff and RMagick4J

First, let's look at getting Gruff working with RMagick4J. Though
RMagick4J is, as of this writing, an incomplete port of ImageMagick
and RMagick, it runs well enough to support Gruff. And that's a pretty
reasonable trade-off, considering how easy it is to install RMagick4J
into JRuby (above) compared to the
[process of setting up RMagick in MatzRuby][5].

    require 'rubygems'
    gem 'rmagick4j'
    gem 'gruff'
    require 'gruff'

    g = Gruff::Line.new("400x300")
    g.title = "My Graph"

    g.data("Apples", [1, 2, 3, 4, 4, 3])
    g.data("Oranges", [4, 8, 7, 9, 8, 9])
    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    g.data("Peaches", [9, 9, 10, 8, 7, 9])
    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}

    g.write('my_fruity_graph.png')

However, since JRuby runs on Java, which sports the
platform-independent Swing GUI toolkit, we can also create a frame to
display the Gruff image rather than writing it to disk. Instead of
`g.write('my_fruity_graph.png')` try this:

    include Java
    import java.io.ByteArrayInputStream
    import javax.imageio.ImageIO
    import javax.swing.JFrame

    class ImagePanel < javax.swing.JPanel
      def initialize(image, x=0, y=0)
        super()
        @image, @x, @y = image, x, y
      end

      def getPreferredSize
        java.awt.Dimension.new(@image.width, @image.height)
      end

      def paintComponent(graphics)
        graphics.draw_image(@image, @x, @y, nil)
      end
    end

    image = ImageIO.read(ByteArrayInputStream.new(g.to_blob.to_java_bytes))
    frame = JFrame.new("My Graph")
    frame.set_bounds 0, 0, image.width + 20, image.height + 40
    frame.add(ImagePanel.new(image, 10, 10))
    frame.visible = true

A few words about this code. First, `include Java` mixes in JRuby's
Java integration features. The next three lines `import` Java classes
as Ruby classes and stores them in constants named the same as the
Java class name. (*Aside*: Be careful when using this technique with a
Java class whose name clashes with a Ruby class of the same name.
Instead, consider an alternate style such as `JFile = java.io.File`.)

`ImagePanel` is a Ruby class that extends Swing's `JPanel`, a Java
class. Note that the `super()` invocation in `ImagePanel`'s
initializer is necessary due to Ruby's default behavior of passing all
the arguments to the superclass initializer, which, in this case, is a
Java constructor that doesn't take any. `getPreferredSize` and
`paintComponent` are expected overrides on `JPanel`, and we use them
to size and paint an image in the panel.

In the last part of the code, we create a Java image object, pass it into
a new `ImagePanel`, pack the panel into a `JFrame`, and show the frame.
`to_java_bytes` is a JRuby-specific method on Ruby's String class that
converts the string to a Java `byte[]`.

If you're following along, and all goes well, you should be seeing
this:

![gruff-simple](http://img.skitch.com/20081215-1bid2e7e9erjxm4dr8tk5fra3u.jpg)

## JMX

[Java Management Extensions (JMX)][6] is a management and monitoring
API and framework for Java. It allows you to query and manipulate a
large number of system metrics and components (called "MBeans"), as
well as register your own. You can control these MBeans both from
within a VM and via remote connections to other VMs. Some examples of
things you can do with JMX are: check memory usage, list threads and
their status, gather garbage collection, class loading and compiler
statistics, or force a garbage collection cycle.

Typical of Java APIs, JMX is pretty verbose, and has its share of
enterprisey `Manager`s and `Factory`s. But thanks to
[Tom Enebo's JMX gem][3], it's easy to get connected to JMX and
retrieve useful information. Here's the code to print out the current
heap memory usage of the JVM:

    def in_mb(value)
      format "%0.2f MB" % (value.to_f / (1024 * 1024))
    end

    server = JMX::MBeanServer.new
    memory = server["java.lang:type=Memory"]
    heap = memory.heap_memory_usage.used
    puts "Size of Heap: #{in_mb(heap)}"

When you run this snippet with JRuby, you should see:

    Size of Heap: 13.83 MB

It's especially nice to explore the JMX MBeans in an IRB session.

    >> server.query_names.select {|b| b.to_s =~ /jruby/ }.each {|b| puts b.to_s }
    org.jruby:type=Runtime,name=4469286,service=ClassCache
    org.jruby:type=Runtime,name=4469286,service=Config
    org.jruby:type=Runtime,name=4469286,service=ParserStats
    org.jruby:type=Runtime,name=4469286,service=JITCompiler
    => [#<Java::JavaxManagement::ObjectName:...]
    >> b = server['org.jruby:type=Runtime,name=4469286,service=Config']
    => #<JMX::MBeans::Org::Jruby::Management::Config:...>
    >> b.version_string
    => "jruby 1.1.6RC1 (ruby 1.8.6 patchlevel 114) (2008-12-03 rev 8263) [i386-java]\n"
    >> b = server['org.jruby:type=Runtime,name=4469286,service=ParserStats']
    => #<JMX::MBeans::Org::Jruby::Management::ParserStats:...>
    >> b.total_parse_time
    => 0.843191

Here, we're exploring some of JRuby's own MBeans, and found out that
the time JRuby spent parsing source code since startup is a little
under a second.

## Graphing the Memory in the VM

Now, let's put all these tools together. Let's start with a class that
samples the memory every two seconds, and saves a rolling window of 50
samples.

    class MemorySampler
      def initialize(&block)
        @samples = []
        @keep = 50
        @interval = 2
        @callback = block
        @server = JMX::MBeanServer.new
        @memory_bean ||= @server["java.lang:type=Memory"]
      end
  
      def memory_usage
        [@memory_bean.heap_memory_usage.used, 
         @memory_bean.non_heap_memory_usage.used]
      end
  
      def samples
        dat = @samples.dup.transpose
        { "Heap" => dat.first, "Non-Heap" => dat.last }
      end
  
      def start
        @thread = Thread.new do
          while true do
            @samples << memory_usage.map {|m| m.to_f / (1024*1024) }
            @samples.shift if @samples.size > @keep
            @callback.call(self) if @callback
            sleep @interval
          end
        end
        @thread.join
      end
    end

Here, we're encapsulating the `JFrame` and `ImagePanel` logic in an
`ImageApp` class.

    class ImageApp
      attr_accessor :title
  
      def initialize(image = nil)
        @title = "Preview"
        @image = image
      end
  
      def image=(image)
        @image = image
        @panel.image = image if @panel
      end
  
      def show
        @frame = JFrame.new(@title)
        @frame.set_bounds 0, 0, @image.width + 20, @image.height + 40
        @panel = @frame.add(ImagePanel.new(@image, 10, 10))
        @frame.visible = true
      end
    end

We'll also need to add a method to `ImagePanel` to assign a new image
to it and force a repaint.

    class ImagePanel
      def image=(image)
        @image = image
        repaint
      end
    end

Let's also add a convenience method to Gruff to create a Java image
object.

    class Gruff::Base
      def to_image
        ImageIO.read(ByteArrayInputStream.new(to_blob.to_java_bytes))
      end
    end


Now, let's start up a MemorySampler with a callback that repeatedly
updates our `ImageApp` with a Gruff image generated from the most
recent samples.

    @app = ImageApp.new
    @app.title = "Memory"
    JMXExamples::MemorySampler.new do |s|
      g = Gruff::Line.new("400x300")
      g.title = @app.title
      g.y_axis_label = "MB"
      s.samples.each_pair {|key,val| g.data(key, val) }
      g.labels = {}
      g.hide_dots = true
      @app.image = g.to_image
      @app.show unless @started
      @started = true
    end.start

Now you should be seeing a window with a continuously updating graph
of the VM's memory usage, all in right around 100 lines of code! Also,
you can easily change the server to which you connect, and monitor the
memory in another VM. For example, here's a profile of Glassfish
starting up and serving requests to a Rails application:

![gf-mem](http://img.skitch.com/20081215-rskuwpd64huedjrfqj8jdnxfhf.jpg)

## Wrap-up

In this article I've given you a taste of the kinds of mashups of Ruby
and Java tech that JRuby so easily allows. JRuby makes installation
and deployment of Gruff graphs easy, and allows you to access VM
statistics and monitoring data in an idiomatically Ruby way with the
JMX gem.

If you're interested in playing with these examples further, do check
out the [bundle I made available on Github][4]. The example code is
included (in a slightly different form from the examples above) in the
`lib/rubyadvent` directory. If you want to use the JRuby that I
include in the bundle, just add `advent-jruby/bin` to your path. Each
example is accessible through a Rake task. Just run `jruby -S rake` to
see what's available:

    To run an example, re-run 'jruby -S rake' with one of the following tasks:
    rake gruff:simple  # Simple Gruff example with JRuby
    rake irb           # Run IRB with Gruff, RMagick4J and JMX loaded
    rake jmx:memory    # Simple JMX memory monitoring example: print memory usage
    rake jmx:tracker   # Gruff/JMX example plotting memory usage over time

Hope you enjoyed this installment of the Ruby Advent Calendar. Happy
holidays, and happy Ruby hacking!

[1]: http://nubyonrails.com/pages/gruff
[2]: http://code.google.com/p/rmagick4j/
[3]: http://www.bloglines.com/blog/ThomasEEnebo?id=53
[4]: http://github.com/nicksieger/advent-jruby/tree/master
[5]: http://rmagick.rubyforge.org/install-faq.html
[6]: http://java.sun.com/javase/technologies/core/mntr-mgmt/javamanagement/
