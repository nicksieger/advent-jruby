module Java2d
  include Java
  import java.io.ByteArrayInputStream
  import javax.imageio.ImageIO
  import javax.swing.JFrame

  class ImagePanel < javax.swing.JPanel
    def initialize(image, x=0, y=0)
      super()
      @image, @x, @y = image, x, y
    end

    def image=(image)
      @image = image
      repaint
    end

    def getPreferredSize
      java.awt.Dimension.new(@image.width, @image.height)
    end

    def paintComponent(graphics)
      graphics.draw_image(@image.java_image, @x, @y, nil)
    end
  end

  class WindowClosed
    def initialize(block = nil)
      @block = block || proc { java.lang.System.exit(0) }
    end
    def method_missing(meth,*args); end
    def windowClosing(event); @block.call; end
  end

  class Image
    def initialize(bytes)
      @bytes = bytes
    end

    def width
      java_image.width
    end

    def height
      java_image.height
    end

    def java_image
      unless @image
        bytes =  String === @bytes ? @bytes.to_java_bytes : @bytes
        @image = ImageIO.read(ByteArrayInputStream.new(bytes))
      end
      @image
    end
  end

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

    def show(&block)
      @frame = JFrame.new(@title)
      @frame.add_window_listener WindowClosed.new(block)
      @frame.set_bounds 0, 0, @image.width + 20, @image.height + 40
      @panel = @frame.add(ImagePanel.new(@image, 10, 10))
      @frame.visible = true
    end
  end
end
