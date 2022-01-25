extends Node2D


var width = ProjectSettings.get_setting("display/window/size/width")
var height = ProjectSettings.get_setting("display/window/size/height")
var texture
var qtree

var contestant_count = 10
var arenas_count = 1
var boundarys = []
var contestants = []
var arenas = []

func _ready():
	$camera.position = Vector2(width/2, height/2)
	texture = ImageTexture.new()
	var image = Image.new()
	image.load("res://assets/battleground/black.png")
	texture.create_from_image(image)
#	for s in Global.SDIW.short_keys:
#		for l in Global.SDIW.long_keys:
#			var d = Global.SDIW.list[s][l]
#			var index = Global.SDIW.data_keys[d]
#			print(s," ",l," ",d,": ",sdiw.data[index] )
#
#	for s in sdiw.stats.short_keys.keys():
#		print(s,sdiw.stats.short_keys[s])
#
#	for l in sdiw.stats.long_keys.keys():
#		print(l,sdiw.stats.long_keys[l])
	
	init_arenas()
	spread_contestants()
	first_fight()

func init_arenas():
	var w = width/arenas_count
	var h = height
	
	for _i in arenas_count:
		var boundary = Battleground.Rectangle.new(_i*w, 0, w, h)
		boundary.index = _i
		boundarys.append(boundary)
		var arena = Battleground.Arena.new()
		arena.boundary = boundary
		arenas.append(arena)
	
	for _i in contestant_count:
		Global.rng.randomize()
		var b = Global.rng.randi_range(0, boundarys.size()-1)
		Global.rng.randomize()
		var x = Global.rng.randi_range(1, w-1) + boundarys[b].x
		Global.rng.randomize()
		var y = Global.rng.randi_range(1, h-1) + boundarys[b].y
		var p = Battleground.Point.new(x, y)
		
		var contestant = Battleground.Contestant.new()
		contestant.point = p
		contestant.index = Global.primary_key.contestant
		contestants.append(contestant)
		
		Global.primary_key.contestant += 1
		
		boundarys[b].points.append(contestant.point)
		
		var s = Sprite.new()
		s.texture = texture
		s.offset = Vector2(x,y)
		add_child(s)

func spread_contestants():
	for contestant in contestants:
		arenas[0].contestants.append(contestant)
		contestant.arena = arenas[0]

func first_fight():
	arenas[0].fight()

func _draw():
	for boundary in boundarys:
		var hue = float(boundary.index)/boundarys.size()
		var color = Color.from_hsv(0.35,1,0.51) 
		var rect = Rect2(Vector2(boundary.x,boundary.y),Vector2(boundary.w,boundary.h))
		draw_rect(rect,color)

func init_qtree():
	var n = 3
	var boundary = Battleground.Rectangle.new(0, 0, width, height)
	qtree = Battleground.QuadTree.new(boundary, 4)
	var count = 100
	var m = 9
	
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
			var p = Battleground.Point.new(x, y)
			qtree.insert(p)
	
	var color
	var rects = []
	qtree.show(rects)
	
	for _i in rects.size():
		Global.rng.randomize()
		var r = Global.rng.randi_range(0, 0.1)
		var h = float(_i+r)/float(rects.size())
		var rect = rects[_i]
		color = Color.from_hsv(h,1,1) 
		draw_rect(rect,color)
