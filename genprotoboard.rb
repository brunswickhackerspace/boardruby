#!/usr/bin/env ruby

boardwidth  = 54	# board width in millimeters
boardlength = 33	# board length in millimeters
inset       = 4		# screw hole distance from edges (also sets corner radii)
horizontal  = true	# horizontal layout

# XML class that can print itself out with indenting, attributes, and children
class Xml
  def initialize(name)
	@name       = name	# node name
	@attributes = {}	# hash of node attributes
	@children   = []	# array of node children
	@text       = nil	# optional node text in lieu of child nodes
  end

  def setText(text)
	@text = text
  end

  def addAttribute(key, value)
	@attributes[key] = value
  end

  def addChild(child)
    @children.push(child)
  end

  def format(level)
	# build up indent string for this node
	indent = ""
	level.times do
	  indent += "  "
	end
	# all tags begin the same way
	tag = "#{indent}<#@name"
	# add any attributes this node has
	@attributes.each do |key, value|
	  tag += " #{key} = \"#{value}\""
	end
	if @children.length != 0
	  # if this node has children, print them with the indent level bumped
	  tag += ">\n"
	  for child in @children
		tag += child.format(level + 1)
	  end
	  # after printing the child nodes, print this node's close tag
	  tag += "#{indent}</#@name>"
	elsif @text
	  # if this node has text content, print it out along with the close tag
	  tag += ">#@text</#@name>"
	else
	  # this node has no text or children, make it a self-closing tag
	  tag += " />"
	end
	# in all cases, add a newline when we're done printing this node
	tag += "\n"
  end

  def to_s
	# the to-string method simply prints out the node with zero indent
	self.format(0)
  end
end

# Line class for lines and traces
class Line < Xml
  def initialize(layer, width, x1, y1, x2, y2)
	super('wire')
	self.addAttribute('x1',    x1)
	self.addAttribute('y1',    y1)
	self.addAttribute('x2',    x2)
	self.addAttribute('y2',    y2)
	self.addAttribute('width', width)
	self.addAttribute('layer', layer)
  end
end

# arc class for curved lines (inherits from Line and adds "curve" attribute)
class Arc < Line
  def initialize(layer, width, x1, y1, x2, y2, angle)
    super(layer, width, x1, y1, x2, y2)
    self.addAttribute('curve', angle)
  end
end

# circle class
class Circle < Xml
  def initialize(layer, width, x, y, radius)
	super('circle')
	self.addAttribute('x',      x)
	self.addAttribute('y',      y)
	self.addAttribute('radius', radius)
	self.addAttribute('width',  width)
	self.addAttribute('layer',  layer)
  end
end

# text class
class Text < Xml
  def initialize(layer, size, x, y, string)
	super('text')
	self.addAttribute('x',     x)
	self.addAttribute('y',     y)
	self.addAttribute('size',  size)
	self.addAttribute('layer', layer)
	self.setText(string)
  end
end

# via/pad class
class Via < Xml
  def initialize(x, y, extent, drill, diameter)
	super('via')
	self.addAttribute('x',        x)
	self.addAttribute('y',        y)
	self.addAttribute('extent',   extent)
	self.addAttribute('drill',    drill)
	self.addAttribute('diameter', diameter)
  end
end

# subelement class for instantiating library items
class Element < Xml
  def initialize(name, library, package, value, x, y)
    super('element')
	self.addAttribute('name',    name)
	self.addAttribute('library', library)
	self.addAttribute('package', package)
	self.addAttribute('value',   value)
	self.addAttribute('x',       x)
	self.addAttribute('y',       y)
  end
end

# vertex class for building polygons
class Vertex < Xml
  def initialize(x, y)
	super('vertex')
	self.addAttribute('x', x)
	self.addAttribute('y', y)
  end
end

# rectangle class
class Rectangle < Xml
  def initialize(layer, x1, y1, x2, y2)
	super('rectangle')
	self.addAttribute('x1',    x1)
	self.addAttribute('y1',    y1)
	self.addAttribute('x2',    x2)
	self.addAttribute('y2',    y2)
	self.addAttribute('layer', layer)
  end
end

# Eagle layer description class
class Layer < Xml
  def initialize(number, name, color, fill, visible, active)
	super('layer')
	self.addAttribute('number',  number)
	self.addAttribute('name',    name)
	self.addAttribute('color',   color)
	self.addAttribute('fill',    fill)
	self.addAttribute('visible', visible)
	self.addAttribute('active',  active)
  end
end

# compute half width and length for center offsets
hwidth  = boardwidth / 2
hlength = boardlength / 2

# build basic document hierarchy elements
eagle     = Xml.new('eagle')
dwg       = Xml.new('drawing')
board     = Xml.new('board')
libraries = Xml.new('libraries')
elements  = Xml.new('elements')
signals   = Xml.new('signals')

# assemble elements into basic document hierarchy
eagle.addChild(dwg)
dwg.addChild(board)
board.addChild(libraries)
board.addChild(elements)
board.addChild(signals)

# install measurement grid values
grid  = Xml.new('grid')
grid.addAttribute('distance',    0.005)
grid.addAttribute('unitdist',    'inch')
grid.addAttribute('unit',        'inch')
grid.addAttribute('altdistance', 0.001)
grid.addAttribute('altunitdist', 'inch')
grid.addAttribute('altunit',     'inch')
grid.addAttribute('style',       'lines')
grid.addAttribute('multiple',    1)
grid.addAttribute('display',     'no')

dwg.addChild(grid)

# add in drilled holes library
holes = Xml.new('library')
holes.addAttribute('name', 'holes')
libraries.addChild(holes)

packages = Xml.new('packages')
holes.addChild(packages)

# add 3mm hole package to library
package = Xml.new('package')
package.addAttribute('name', '3,0')
description = Xml.new('description')
description.setText('&lt;b&gt;MOUNTING HOLE&lt;/b&gt; 3.0 mm with drill center')
package.addChild(description)
layer = 51 # tDocu
width = 2.4892
aoffset = 2.159
arc = Arc.new(layer, width, -aoffset, 0, 0, -aoffset, 90)
arc.addAttribute('cap', 'flat')
package.addChild(arc)
arc = Arc.new(layer, width, 0, aoffset, aoffset, 0, -90)
arc.addAttribute('cap', 'flat')
package.addChild(arc)
width = 0.4572
package.addChild(Circle.new(layer, width, 0, 0, 0.762))
layer = 21 # tPlace
width = 0.1524
package.addChild(Circle.new(layer, width, 0, 0, 3.429))
width  = 2.032
package.addChild(Circle.new(layer, width, 0, 0, 1.6))
radius = 3.048
layer  = 39 # tKeepout
package.addChild(Circle.new(layer, width, 0, 0, radius))
layer  = 40 # bKeepout
package.addChild(Circle.new(layer, width, 0, 0, radius))
layer  = 41 # tRestrict
package.addChild(Circle.new(layer, width, 0, 0, radius))
layer  = 42 # bRestrict
package.addChild(Circle.new(layer, width, 0, 0, radius))
layer  = 43 # vRestrict
package.addChild(Circle.new(layer, width, 0, 0, radius))
layer = 48 # Document
size = 1.27
package.addChild(Text.new(layer, size, -1.27, -3.81, '3,0'))
hole = Xml.new('hole')
hole.addAttribute('x', 0)
hole.addAttribute('y', 0)
hole.addAttribute('drill', 3)

packages.addChild(package)

# add Eagle layer descriptions
layers = Xml.new('layers')

layers.addChild(Layer.new("1",   "Top",           "4",  "1", "yes", "yes"))
layers.addChild(Layer.new("2",   "Route2",        "1",  "3", "no",  "yes"))
layers.addChild(Layer.new("3",   "Route3",        "4",  "3", "no",  "yes"))
layers.addChild(Layer.new("4",   "Route4",        "1",  "4", "no",  "yes"))
layers.addChild(Layer.new("5",   "Route5",        "4",  "4", "no",  "yes"))
layers.addChild(Layer.new("6",   "Route6",        "1",  "8", "no",  "yes"))
layers.addChild(Layer.new("7",   "Route7",        "4",  "8", "no",  "yes"))
layers.addChild(Layer.new("8",   "Route8",        "1",  "2", "no",  "yes"))
layers.addChild(Layer.new("9",   "Route9",        "4",  "2", "no",  "yes"))
layers.addChild(Layer.new("10",  "Route10",       "1",  "7", "no",  "yes"))
layers.addChild(Layer.new("11",  "Route11",       "4",  "7", "no",  "yes"))
layers.addChild(Layer.new("12",  "Route12",       "1",  "5", "no",  "yes"))
layers.addChild(Layer.new("13",  "Route13",       "4",  "5", "no",  "yes"))
layers.addChild(Layer.new("14",  "Route14",       "1",  "6", "no",  "yes"))
layers.addChild(Layer.new("15",  "Route15",       "4",  "6", "no",  "yes"))
layers.addChild(Layer.new("16",  "Bottom",        "1",  "1", "yes", "yes"))
layers.addChild(Layer.new("17",  "Pads",          "2",  "1", "yes", "yes"))
layers.addChild(Layer.new("18",  "Vias",          "2",  "1", "yes", "yes"))
layers.addChild(Layer.new("19",  "Unrouted",      "6",  "1", "yes", "yes"))
layers.addChild(Layer.new("20",  "Dimension",    "15",  "1", "yes", "yes"))
layers.addChild(Layer.new("21",  "tPlace",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("22",  "bPlace",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("23",  "tOrigins",     "15",  "1", "yes", "yes"))
layers.addChild(Layer.new("24",  "bOrigins",     "15",  "1", "yes", "yes"))
layers.addChild(Layer.new("25",  "tNames",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("26",  "bNames",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("27",  "tValues",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("28",  "bValues",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("29",  "tStop",         "7",  "3", "no",  "yes"))
layers.addChild(Layer.new("30",  "bStop",         "7",  "6", "no",  "yes"))
layers.addChild(Layer.new("31",  "tCream",        "7",  "4", "no",  "yes"))
layers.addChild(Layer.new("32",  "bCream",        "7",  "5", "no",  "yes"))
layers.addChild(Layer.new("33",  "tFinish",       "6",  "3", "no",  "yes"))
layers.addChild(Layer.new("34",  "bFinish",       "6",  "6", "no",  "yes"))
layers.addChild(Layer.new("35",  "tGlue",         "7",  "4", "no",  "yes"))
layers.addChild(Layer.new("36",  "bGlue",         "7",  "5", "no",  "yes"))
layers.addChild(Layer.new("37",  "tTest",         "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("38",  "bTest",         "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("39",  "tKeepout",      "4", "11", "yes", "yes"))
layers.addChild(Layer.new("40",  "bKeepout",      "1", "11", "yes", "yes"))
layers.addChild(Layer.new("41",  "tRestrict",     "4", "10", "yes", "yes"))
layers.addChild(Layer.new("42",  "bRestrict",     "1", "10", "yes", "yes"))
layers.addChild(Layer.new("43",  "vRestrict",     "2", "10", "yes", "yes"))
layers.addChild(Layer.new("44",  "Drills",        "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("45",  "Holes",         "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("46",  "Milling",       "3",  "1", "no",  "yes"))
layers.addChild(Layer.new("47",  "Measures",      "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("48",  "Document",      "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("49",  "Reference",     "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("50",  "dxf",           "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("51",  "tDocu",         "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("52",  "bDocu",         "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("53",  "tGND_GNDA",     "7",  "9", "no",  "no" ))
layers.addChild(Layer.new("54",  "bGND_GNDA",     "1",  "9", "no",  "no" ))
layers.addChild(Layer.new("56",  "wert",          "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("91",  "Nets",          "2",  "1", "no",  "no" ))
layers.addChild(Layer.new("92",  "Busses",        "1",  "1", "no",  "no" ))
layers.addChild(Layer.new("93",  "Pins",          "2",  "1", "no",  "no" ))
layers.addChild(Layer.new("94",  "Symbols",       "4",  "1", "no",  "no" ))
layers.addChild(Layer.new("95",  "Names",         "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("96",  "Values",        "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("97",  "Info",          "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("98",  "Guide",         "6",  "1", "no",  "no" ))
layers.addChild(Layer.new("100", "Muster",        "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("101", "Patch_Top",    "12",  "4", "yes", "yes"))
layers.addChild(Layer.new("102", "Vscore",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("103", "fp3",           "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("104", "Name",          "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("105", "Beschreib",     "9",  "1", "yes", "yes"))
layers.addChild(Layer.new("106", "BGA-Top",       "4",  "1", "yes", "yes"))
layers.addChild(Layer.new("107", "BD-Top",        "5",  "1", "yes", "yes"))
layers.addChild(Layer.new("108", "fp8",           "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("109", "fp9",           "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("110", "fp0",           "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("111", "LPC17xx",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("112", "tPlaceRed",    "12",  "1", "yes", "yes"))
layers.addChild(Layer.new("113", "tPlaceBlue",    "9",  "1", "yes", "yes"))
layers.addChild(Layer.new("116", "Patch_BOT",     "9",  "4", "yes", "yes"))
layers.addChild(Layer.new("121", "_tsilk",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("122", "_bsilk",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("123", "tTestmark",     "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("124", "bTestmark",     "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("125", "_tNames",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("126", "_bNames",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("127", "_tValues",      "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("128", "_bValues",      "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("131", "tAdjust",       "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("132", "bAdjust",       "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("144", "Drill_legend",  "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("151", "HeatSink",      "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("152", "_bDocu",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("199", "Contour",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("200", "200bmp",        "1", "10", "yes", "yes"))
layers.addChild(Layer.new("201", "201bmp",        "2",  "1", "no",  "no" ))
layers.addChild(Layer.new("202", "202bmp",        "3",  "1", "no",  "no" ))
layers.addChild(Layer.new("203", "203bmp",        "4", "10", "yes", "yes"))
layers.addChild(Layer.new("204", "204bmp",        "5", "10", "yes", "yes"))
layers.addChild(Layer.new("205", "205bmp",        "6", "10", "yes", "yes"))
layers.addChild(Layer.new("206", "206bmp",        "7", "10", "yes", "yes"))
layers.addChild(Layer.new("207", "207bmp",        "8", "10", "yes", "yes"))
layers.addChild(Layer.new("208", "208bmp",        "9", "10", "yes", "yes"))
layers.addChild(Layer.new("209", "209bmp",        "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("210", "210bmp",        "7",  "1", "no",  "yes"))
layers.addChild(Layer.new("211", "211bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("212", "212bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("213", "213bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("214", "214bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("215", "215bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("216", "216bmp",        "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("217", "217bmp",       "18",  "1", "no",  "no" ))
layers.addChild(Layer.new("218", "218bmp",       "19",  "1", "no",  "no" ))
layers.addChild(Layer.new("219", "219bmp",       "20",  "1", "no",  "no" ))
layers.addChild(Layer.new("220", "220bmp",       "21",  "1", "no",  "no" ))
layers.addChild(Layer.new("221", "221bmp",       "22",  "1", "no",  "no" ))
layers.addChild(Layer.new("222", "222bmp",       "23",  "1", "no",  "no" ))
layers.addChild(Layer.new("223", "223bmp",       "24",  "1", "no",  "no" ))
layers.addChild(Layer.new("224", "224bmp",       "25",  "1", "no",  "no" ))
layers.addChild(Layer.new("248", "Housing",       "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("249", "Edge",          "7",  "1", "yes", "yes"))
layers.addChild(Layer.new("250", "Descript",      "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("251", "SMDround",      "7",  "1", "no",  "no" ))
layers.addChild(Layer.new("254", "cooling",       "7",  "1", "yes", "yes"))

dwg.addChild(layers)

# add "plain" board element to hold board features
plain = Xml.new('plain')
board.addChild(plain)

# minus signs for negative power buses

layer = 21     # tPlace
width = 0.4064

#plain.addChild(Line.new(layer, width, -33.528,  23.876, -33.528,  22.606))
#plain.addChild(Line.new(layer, width,  33.528,  23.876,  33.528,  22.606))
#plain.addChild(Line.new(layer, width, -33.528, -16.764, -33.528, -18.034))
#plain.addChild(Line.new(layer, width,  33.528, -16.764,  33.528, -18.034))

# plus signs for positive power buses

size = 2.54

#plain.addChild(Text.new(layer, size, -34.544, -24.638, '+'))
#plain.addChild(Text.new(layer, size,  32.512, -24.638, '+'))
#plain.addChild(Text.new(layer, size,  32.512,  16.002, '+'))
#plain.addChild(Text.new(layer, size, -34.798,  16.002, '+'))

# row numbers

x    = -37.338
y1   =  15.24
y2   = -16.256
size =   1.016

30.times do |row|
	#plain.addChild(Text.new(layer, size, x, y1, row))
	#plain.addChild(Text.new(layer, size, x, y2, row))
	x += 2.54
end

# no solder mask on back

layer = 30 # bStop

plain.addChild(Rectangle.new(layer, -hwidth, -hlength, hwidth, hlength))

# board outline

layer = 20 # Dimension
width = 0.127

plain.addChild(Arc.new(layer, width, hwidth, hlength - inset, hwidth - inset, hlength, 90))
plain.addChild(Line.new(layer, width, hwidth - inset, hlength, -hwidth + inset, hlength))
plain.addChild(Arc.new(layer, width, hwidth - inset, -hlength, hwidth, -hlength + inset, 90))
plain.addChild(Line.new(layer, width, hwidth, -hlength + inset, hwidth, hlength - inset))
plain.addChild(Arc.new(layer, width, -hwidth + inset, hlength, -hwidth, hlength - inset, 90))
plain.addChild(Line.new(layer, width, hwidth - inset, -hlength, -hwidth + inset, -hlength))
plain.addChild(Arc.new(layer, width, -hwidth, -hlength + inset, -hwidth + inset, -hlength, 90))
plain.addChild(Line.new(layer, width, -hwidth, -hlength + inset, -hwidth, hlength - inset))

# mounting holes

elements.addChild(Element.new('H1', 'holes', '3,0', 'MOUNT-HOLE3.0', hwidth - inset, hlength - inset))
elements.addChild(Element.new('H2', 'holes', '3,0', 'MOUNT-HOLE3.0', -hwidth + inset, hlength - inset))
elements.addChild(Element.new('H3', 'holes', '3,0', 'MOUNT-HOLE3.0', hwidth - inset, -hlength + inset))
elements.addChild(Element.new('H4', 'holes', '3,0', 'MOUNT-HOLE3.0', -hwidth + inset, -hlength + inset))

# draw pads and traces

nholes    = 5
npg       = 2
gap       = 1
if horizontal
	prows     = 3
	extrarows = 0
	space     = boardwidth - (2 * (inset + 3))
else
	prows     = 2
	extrarows = 1
	space     = boardlength - (2 * (inset + 1.5))
end
pitch     = 0.1 * 25.4
nrows     = (space / pitch).to_i

startrow  = (nrows - 1) / 2.0 # coerce to floating point to avoid truncation

if horizontal
	x  = startrow * pitch
	ty = (nholes + (gap / 2.0)) * pitch # also coerce to floating point
	by = -ty
else
	y  = startrow * pitch
	rx = (nholes + (gap / 2.0)) * pitch # also coerce to floating point
	lx = -rx
end

$net      = 1
layer     = 16 # Bottom
width     = 0.4064

# draw a line of pads with traces linking them
def makelink(layer, width, x, y, xincr, yincr, n)
	signal = Xml.new('signal')
	signal.addAttribute('name', "N$#{$net}")
	n.times do |hole|
		curx = x + (hole * xincr)
		cury = y + (hole * yincr)
		signal.addChild(Via.new(curx, cury, '1-16', 1.2, 1.9304))
		if hole != 0
			signal.addChild(Line.new(layer, width, curx, cury, curx - xincr, cury - yincr))
		end
	end

	$net += 1
	return signal
end

# two sets of parallel lines of connected pads
(nrows + extrarows).times do |count|
	if horizontal
		signals.addChild(makelink(layer, width, x, ty, 0, -pitch, nholes))
		signals.addChild(makelink(layer, width, x, by, 0,  pitch, nholes))
		x -= pitch
	else
		signals.addChild(makelink(layer, width, lx, y,  pitch, 0, nholes))
		signals.addChild(makelink(layer, width, rx, y, -pitch, 0, nholes))
		y -= pitch
	end
end

# connected pads for power buses

if horizontal
	x = startrow * pitch
else
	y = (startrow - 1) * pitch
end

npg.times do |count|
	if horizontal
		# one pair of power buses between the parallel traces
		signals.addChild(makelink(layer, width, x, pitch/2 - (pitch * count), -pitch, 0, nrows))
	else
		# two pairs of power buses outside the parallel traces
		signals.addChild(makelink(layer, width, lx + (count - npg) * pitch, y, 0, -pitch, nrows - 2))
		signals.addChild(makelink(layer, width, rx - (count - npg) * pitch, y, 0, -pitch, nrows - 2))
	end
end

# unconnected pads for further prototyping area

prows.times do |prow|
	if horizontal
		6.times do |rank|
			signals.addChild(makelink(layer, width,  x - (prow - 3) * pitch, ty - (rank + 3) * pitch, pitch, pitch, 1))
			signals.addChild(makelink(layer, width, -x + (prow - 3) * pitch, ty - (rank + 3) * pitch, pitch, pitch, 1))
		end
	else
		(nrows - 2).times do |row|
			signals.addChild(makelink(layer, width, lx - (npg + prow + 1) * pitch, y - row * pitch, pitch, pitch, 1))
			signals.addChild(makelink(layer, width, rx + (npg + prow + 1) * pitch, y - row * pitch, pitch, pitch, 1))
		end
	end
end

# box for badge owner's name

layer = 21 # tDocu

hrwidth = hwidth - (inset + 3)
plain.addChild(Rectangle.new(layer, -hrwidth, hlength - 0.5, hrwidth, hlength - inset - 1.5))

# Brunswick Hackerspace text

label = 'Brunswick Hackerspace'
size  = 2

plain.addChild(Text.new(layer, size, -(hrwidth - 2), -hlength + 1, label))

# Brunswick Hackerspace logo (dimensions from Lisa Horne Cook's design)

logosize   = 1.4			 # scaling factor to fit nicely
logowidth  = 26.6 * logosize
logoheight = 10.1 * logosize
logoflex   =  6.1 * logosize
logotop    = hlength - 6
width      = 0.4064

hlogowidth = logowidth / 2.0

polygon = Xml.new('polygon')
polygon.addAttribute('layer', layer)
polygon.addAttribute('width', width)
polygon.addChild(Vertex.new(-hlogowidth, logotop))
polygon.addChild(Vertex.new(0, logotop - logoflex))
polygon.addChild(Vertex.new(hlogowidth, logotop))
polygon.addChild(Vertex.new(hlogowidth, logotop - logoheight))
polygon.addChild(Vertex.new(0, logotop - (logoheight + logoflex)))
polygon.addChild(Vertex.new(-hlogowidth, logotop - logoheight))

plain.addChild(polygon)

# print out finished XML document

print "<?xml version = \"1.0\" encoding = \"UTF-8\" ?>\n"
print "<!DOCTYPE eagle SYSTEM \"eagle.dtd\">\n"
print eagle.to_s
