extends Node2D


var width = ProjectSettings.get_setting("display/window/size/width")
var height = ProjectSettings.get_setting("display/window/size/height")
var qtree

func _ready():
	$camera.position = Vector2(width/2, height/2)
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load("res://assets/arena/black.png")
	texture.create_from_image(image)
	
	var n = 3
	var boundary = Arena.Rectangle.new(0, 0, width, height)
	qtree = Arena.QuadTree.new(boundary, 4)
	
	for _i in n:
		for _j in n:
				
			Global.rng.randomize()
			var x = Global.rng.randi_range(0, width)
			Global.rng.randomize()
			var y = Global.rng.randi_range(0, height)
			var s = Sprite.new()
			s.texture = texture
			s.offset = Vector2(x,y)
			add_child(s)
			var p = Arena.Point.new(x, y)
			qtree.insert(p)
			
	_draw()

func _draw():
	var color
	var rects = []
	qtree.show(rects)
	print(rects.size())
	
	for _i in rects.size():
		Global.rng.randomize()
		var r = Global.rng.randi_range(0, 0.1)
		var h = float(_i+r)/float(rects.size())
		var rect = rects[_i]
		color = Color.from_hsv(h,1,1) 
		draw_rect(rect,color)
