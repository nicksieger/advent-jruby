require 'RMagick'
require 'gruff'
require 'java2d/image'

class Gruff::Base
  def to_image
    Java2d::Image.new(to_blob)
  end
end

class GruffExamples
  def self.simple
    g = Gruff::Line.new
    g.title = "My Graph"

    g.data("Apples", [1, 2, 3, 4, 4, 3])
    g.data("Oranges", [4, 8, 7, 9, 8, 9])
    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    g.data("Peaches", [9, 9, 10, 8, 7, 9])

    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}

    app = Java2d::ImageApp.new(g.to_image)
    app.title = g.title
    app.show
  end

  def self.memory_visualizer
    @app = Java2d::ImageApp.new
    @app.title = "Memory"
    @sampler = JMXExamples::MemorySampler.new do |s|
      g = Gruff::Line.new
      g.title = @app.title
      g.y_axis_label = "MB"
      s.samples.each_pair {|key,val| g.data(key, val) }
      g.labels = {}
      g.hide_dots = true
      @app.image = g.to_image
      @app.show unless @started
      @started = true
    end
    @sampler.start
  end
end
