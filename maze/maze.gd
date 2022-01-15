extends Node2D

#thank for code https://github.com/kidscancode
const N = 1
const E = 2
const S = 4
const W = 8
const step = 3

var steped_walls = {Vector2(0, -step): N, Vector2(step, 0): E, 
				  Vector2(0, step): S, Vector2(-step, 0): W}
var cell_walls = {Vector2(0, -1): N, Vector2(1, 0): E, 
				  Vector2(0, 1): S, Vector2(-1, 0): W}
var neighbors = [
	Vector2(0, -1), 
	Vector2(1, 0),
	Vector2(0, 1), 
	Vector2(-1, 0)
	]
var deadends = []
var roads = []
var crossroads = []
var cells = []
var connects = {}

var a = 31
var tile_size = 64  # tile size (in pixels)
var width = a  # width of map (in tiles)
var height = a # height of map (in tiles)
var zoom = 3
var half

# get a reference to the map for convenience
onready var map = $tileMap

func _ready():
	$camera2D.zoom = Vector2(zoom, zoom)
	$camera2D.position = map.map_to_world(Vector2(width/2, height/2))
	
	half = ceil(height / 2)
	
	tile_size = map.cell_size
	make_maze()
	find_deadends()

func make_maze():
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	map.clear()
	
	for x in range(width):
		for y in range(height):
			map.set_cellv(Vector2(x, y), N|E|S|W)
			
	build_center(unvisited)
		
	for x in range(0, width, step):
		for y in range(0, height, step):
			if (map.get_cellv(Vector2(x, y)) == N|E|S|W) && !check_center(x,y):
				unvisited.append(Vector2(x, y))
	
	var current = Vector2(3, 3)
	unvisited.erase(current)
	
	# execute recursive backtracker algorithm
	while unvisited.size() > 0:
		var neighbors_ = check_neighbors(current, unvisited)
		
		if neighbors_.size() > 0:
			Global.rng.randomize()
			var next = neighbors_[Global.rng.randi() % neighbors_.size()]
			
			stack.append(current)
			# remove walls from *both* cells
			var dir = next - current
			var current_walls = map.get_cellv(current) - steped_walls[dir]
			var next_walls = map.get_cellv(next) - steped_walls[-dir]
			var way = dir/step
			var index_f = neighbors.find(way)
			var shifted_way = neighbors[(2+index_f)%neighbors.size()]
			connect_cells(current, way)
			for _i in step - 2:
				var cell = current + way * (_i + 1)
				connect_cells(cell, way)
			connect_cells(next, shifted_way)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()

func build_center(unvisited):
	map.set_cellv(Vector2(half, half), 0)
	var ways_ = [E,S,W,N]
	
	for _i in ways_.size():
		var cell = Vector2(half, half)
		var neighbor = neighbors[_i]
		cell = cell + neighbor
		map.set_cellv(cell, 15-ways_[(_i+1)%ways_.size()])
		connect_cells(cell, neighbor)
		
		for _j in half-2:
			cell = cell + neighbor
			connect_cells(cell, neighbor)
			
			if _j == step*2+1:
				unvisited.append(cell)
		#unvisited.append(cell + neighbor)
#				for _k in 2:
#					var cell_ = cell
#
#					for _l in step:
#						connect_cells(cell_, neighbors[(_i+1+_k*2)%ways_.size()])
#						cell_ = cell_ + neighbors[(_i+1+_k*2)%ways_.size()]
			
#		for _j in 2:
#			var cell_ = cell + neighbor
#
#			for _l in half:
#				connect_cells(cell_, neighbors[(_i+1+_j*2)%ways_.size()])
#				cell_ = cell_ + neighbors[(_i+1+_j*2)%ways_.size()]
			
		cell =  Vector2(half, half) + neighbor *2
		connect_cells(cell, neighbors[(_i+3)%ways_.size()])
		cell = cell + neighbors[(_i+3)%ways_.size()]
		connect_cells(cell, neighbors[(_i+3)%ways_.size()])
		cell = cell + neighbors[(_i+3)%ways_.size()]
		connect_cells(cell, neighbors[(_i+2)%ways_.size()])
		cell = cell + neighbors[(_i+2)%ways_.size()]
		connect_cells(cell, neighbors[(_i+1)%ways_.size()])
		
		for _j in 2:
			cell = Vector2(half, half) + neighbor * 3
			
			for _l in 3:
				connect_cells(cell, neighbors[(_i+1+_j*2)%ways_.size()])
				cell = cell + neighbors[(_i+1+_j*2)%ways_.size()]
		
func check_center(x_,y_):
	var size = step
	var x = ( x_ <= half + size && x_ >= half - size )
	var y = ( y_ <= half + size && y_ >= half - size )
	return x&&y

func check_neighbors(cell, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in steped_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list

func connect_cells(cell, neighbor):
	if map.get_cellv(cell) & cell_walls[neighbor]:
		var walls = map.get_cellv(cell) - cell_walls[neighbor]
		var n_walls = map.get_cellv(cell+neighbor) - cell_walls[-neighbor]
		map.set_cellv(cell, walls)
		map.set_cellv(cell+neighbor, n_walls)

func find_deadends():
	var ends = []
	
	for neighbor in neighbors:
		ends.append(N|E|S|W-cell_walls[neighbor])
	
	for x in range(width):
		for y in range(height):
			var tile = map.get_cellv(Vector2(x, y)) 
			var index_f = ends.find(tile)
			
			if index_f != -1:
				deadends.append(tile)
	
	for x in range(width):
		for y in range(height):
			var cell = Global.Cell.new()
			cell.index = x * width + y
			cell.grid = Vector2(x, y)
			cell.tile = map.get_cellv(cell.grid)
			cells.append(cell)
			
			if cell.tile != N|E|S|W:
				connects[cell.index] = []
				
				connects[cell.index].append(1)#neighbor
	
	print(deadends.size())
	check_tile_include(3,0)
	
func check_tile_include(tile, way):
	var reverse = N|E|S|W - tile + 1
	var ways = [N,E,S,W]
	var binary = []
	var bin = pow(2,ways.size()-1)
	
	for _i in ways.size():
		var flag =reverse > bin
		
		if reverse > bin:
			reverse -= bin
		
		bin/=2
		binary.append(flag)
		print(reverse)
	
	print(binary)
