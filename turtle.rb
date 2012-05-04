#!/usr/bin/env ruby

class ::Array
  def x
    self[0] if any?
  end

  def y
    self[1] if size > 0
  end
end

class Canvas
  attr_reader :size, :points, :last

  def initialize(size=nil)
    @points = Hash.new { |hash,key| hash[key] = []} #hash with default value of empty array
    @last = nil
    self.size = size || 0
  end

  def size=(s)
    @size = s
    center_pt = s / 2
    add(center_pt, center_pt) if s > 0
  end

  def add(x, y)
    @points[y] << x
    @last = [x, y]
    self
  end

  def contains?(x, y)
    @points[y] && @points[y].include?(x)
  end

  def format_line(y)
    chars = []
    (0...size).each { |x| chars << (contains?(x, y) ? 'X' : '.') }
    chars.join(' ') + "\n"
  end

  def to_s
    s = ''
    (0...size).each { |y| s << format_line(y) }
    s.chomp
  end

end

class Turtle

  attr_reader :canvas, :orientation

  def initialize(size=nil)
    @canvas       = Canvas.new(size)
    @orientation  = 0
  end

  def rotate(degrees)
    @orientation += degrees
    @orientation = @orientation % 360
  end

  def size=(s)
    @canvas.size = s
  end

  def right(degrees)
    rotate(degrees)
  end

  def left(degrees)
    rotate(degrees * -1)
  end

  def endpoint_x(units)
    ([0, 1, 1, 1, 0, -1, -1, -1][ @orientation / 45] * units) + @canvas.last.x
  end

  def endpoint_y(units)
    ([-1, -1, 0, 1, 1, 1, 0, -1][ @orientation / 45] * units) + @canvas.last.y
  end

  def endpoint(units)
    [endpoint_x(units), endpoint_y(units)]
  end

  def step_axis(current, target)
    return current if current == target
    current + (target > current ? 1 : -1)
  end

  def step(current, target)
    new_x = step_axis(current.x, target.x)
    new_y = step_axis(current.y, target.y)
    [new_x, new_y]
  end

  def move(units)
    move_to = endpoint(units)
    @canvas.add(*step(@canvas.last, move_to)) until(@canvas.last == move_to)
  end

  def to_s
    @canvas.to_s
  end

  # Command aliases
  alias :fd :move
  alias :rt :right
  alias :lt :left

  def bk(units)
    move(units * -1)
  end

  def process_cmd(str)
    method, arg = str.split
    execute(method, arg)
  end

  def execute(method, arg)
    self.send(method.downcase, arg.to_i)
  end

  def split_cmds(str)
    parts = str.strip.split
    (0...(parts.size / 2)).inject([]) { |arr, idx| arr << [parts[idx * 2], parts[(idx * 2) + 1]]; arr }
  end

  def repeat(line)
    outer, inner = line.gsub(/]/,'').split('[')
    commands = split_cmds(inner)
    outer.gsub(/REPEAT\ /,'').to_i.times { commands.each { |method, arg| execute(method, arg) } }
  end

  def process(str)
    str.split("\n").each { |line| (line =~ /REPEAT/ ? repeat(line) : process_cmd(line)) }
  end

end

t = Turtle.new

# Usage: cat afile.logo | ruby turtle.rb
ARGF.each_with_index do |line, idx|
  break if idx == 0 && line.to_i == 0 #i.e., if rspec
  t.canvas.size = line.to_i if idx == 0
  t.process(line) if idx > 1
end

puts t
