extends Node2D


var width = ProjectSettings.get_setting("display/window/size/width")
var height = ProjectSettings.get_setting("display/window/size/height")
var texture
var qtree

var contestant_counter = 10
var arena_counter = 1

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
	init_contestants()
	spread_contestants()
	first_fight()

func init_arenas():
	var w = width/arena_counter
	var h = height
	
	for _i in arena_counter:
		var boundary = Battleground.Rectangle.new(_i*w, 0, w, h)
		boundary.index = _i
		Global.array.boundarys.append(boundary)
		var arena = Battleground.Arena.new()
		arena.boundary = boundary
		Global.array.arenas.append(arena)

func init_contestants():
	var w = width/arena_counter
	var h = height
	
	for _i in contestant_counter:
		Global.rng.randomize()
		var b = Global.rng.randi_range(0, Global.array.boundarys.size()-1)
		Global.rng.randomize()
		var x = Global.rng.randi_range(1, w-1) + Global.array.boundarys[b].x
		Global.rng.randomize()
		var y = Global.rng.randi_range(1, h-1) + Global.array.boundarys[b].y
		var p = Battleground.Point.new(x, y)
		
		var contestant = Battleground.Contestant.new(Global.list.primary_key.contestant, p)
		Global.array.contestants.append(contestant)
		
		Global.array.boundarys[b].points.append(contestant.point)
		
		var s = Sprite.new()
		s.name = String(Global.list.primary_key.contestant)
		s.texture = texture
		s.offset = Vector2(x,y)
		$sprites.add_child(s)
		
		Global.list.primary_key.contestant += 1

func spread_contestants():
	for contestant in Global.array.contestants:
		var team_name = String(contestant.index)
		Global.array.arenas[0].new_team(team_name, contestant.index)
		contestant.team = team_name
		contestant.arena = Global.array.arenas[0]

func first_fight():
	Global.array.arenas[0].fight()

func _draw():
	for boundary in Global.array.boundarys:
		var hue = float(boundary.index)/Global.array.boundarys.size()
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
