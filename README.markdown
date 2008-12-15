In this installment of the Ruby Advent Calendar 2008, I'll show you
how easy it is to use JRuby to mix and match both Ruby and Java tools
to quickly create a simple memory monitoring program.

We'll be using the venerable [Gruff graphing library][1], along with
[RMagick4j][2], a Java port of the ImageMagick/RMagick imaging library
for JRuby, and the [jmx gem][3] as a nice Ruby wrapper around Java's
JMX (Java Management Extensions) apis.

If you already have a JRuby installation you'd like to use to play
around with the code for this article, you can install the gems we
need as follows:

    jruby -S gem install gruff rmagick4j jmx

(If you haven't played with JRuby before or don't have an install
handy, a [complete download is available][4] of the code for this
article, including JRuby and all dependencies.)

## Gruff and RMagick4J

First, let's look at getting Gruff working with rmagick4j. Though
rmagick4j is, as of this writing, an incomplete port of ImageMagick
and RMagick, it runs well enough to support Gruff. And that's a pretty
reasonable trade-off, considering how easy it is to install rmagick4j
into JRuby (above) compared to the [process of setting up RMagick in MatzRuby][5].

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

If you're following along, if all goes well, you should be seeing
this:

![gruff-simple](http://img.skitch.com/20081215-1bid2e7e9erjxm4dr8tk5fra3u.jpg)

## JMX



[1]: http://nubyonrails.com/pages/gruff
[2]: http://code.google.com/p/rmagick4j/
[3]: http://www.bloglines.com/blog/ThomasEEnebo?id=53
[4]: http://github.com/nicksieger/advent-jruby/tree/master
[5]: http://rmagick.rubyforge.org/install-faq.html
