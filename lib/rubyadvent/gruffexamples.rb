require 'RMagick'
require 'gruff'
require 'java2d/image'

class GruffExamples
  def self.simple
    g = Gruff::Line.new
    g.title = "My Graph"

    g.data("Apples", [1, 2, 3, 4, 4, 3])
    g.data("Oranges", [4, 8, 7, 9, 8, 9])
    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    g.data("Peaches", [9, 9, 10, 8, 7, 9])

    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}

    Java2d::Image.new(g.to_blob).preview
  end
end
