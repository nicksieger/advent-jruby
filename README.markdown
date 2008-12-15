In this installment of the Ruby Advent Calendar 2008, I'll show you
how easy it is to use JRuby to mix and match both Ruby and Java tools
to quickly create a simple memory monitoring application.

We'll be using the venerable [Gruff graphing library][1], along with
[RMagick4j][2], a Java port of the ImageMagick/RMagick imaging library
for JRuby, and the [jmx gem][3] as a nice Ruby wrapper around Java's Java
Management Extensions (JMX) apis.

If you already have a JRuby installation you'd like to use to play
around with the code for this article, you can install the gems we
need as follows:

    jruby -S gem install gruff rmagick4j jmx

(If you haven't played with JRuby before or don't have an install
handy, a [complete download is available][4] of the code for this
article, including JRuby and all dependencies.)

First, let's look at getting Gruff working with rmagick4j. Though
rmagick4j is, as of this writing, an incomplete port of ImageMagick
and RMagick, it runs well enough to support Gruff.

    require 'rubygems'
    gem 'rmagick4j'
    gem 'gruff'
    require 'gruff'

    g = Gruff::Line.new
    g.title = "My Graph"

    g.data("Apples", [1, 2, 3, 4, 4, 3])
    g.data("Oranges", [4, 8, 7, 9, 8, 9])
    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    g.data("Peaches", [9, 9, 10, 8, 7, 9])

    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}
    g.write('my_fruity_graph.png')

However, since JRuby runs on Java, which sports the
platform-independent Swing GUI toolkit, we can also create a frame to
display the Gruff image rather than writing it to disk.

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


[1]: http://nubyonrails.com/pages/gruff
[2]: http://code.google.com/p/rmagick4j/
[3]: http://www.bloglines.com/blog/ThomasEEnebo?id=53
[4]: http://github.com/nicksieger/advent-jruby/tree/master
