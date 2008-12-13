module Java2d
  include Java
  import java.io.ByteArrayInputStream
  import javax.imageio.ImageIO
  import javax.swing.JFrame

  class Image
    class JImagePanel < javax.swing.JPanel
      def initialize(image, x=0, y=0)
        super()
        @image, @x, @y = image, x, y
      end

      def image=(image)
        @image = image
        invalidate
      end

      def getPreferredSize
        java.awt.Dimension.new(@image.width, @image.height)
      end

      def paintComponent(graphics)
        graphics.draw_image(@image, @x, @y, nil)
      end
    end

    class WindowClosed
      def initialize(block = nil)
        @block = block || proc { java.lang.System.exit(0) }
      end
      def method_missing(meth,*args); end
      def windowClosing(event); @block.call; end
    end

    def initialize(bytes)
      bytes = bytes.to_java_bytes if String === bytes
      @image = ImageIO.read(ByteArrayInputStream.new(bytes))
    end

    def preview(&block)
      frame = JFrame.new("Preview")
      frame.add_window_listener WindowClosed.new(block)
      frame.set_bounds 0, 0, @image.width + 20, @image.height + 40
      frame.add JImagePanel.new(@image, 10, 10)
      frame.visible = true
    end
  end
end