extends Node2D

#thank for code https://github.com/kidscancode
const N = 1
const E = 2
const S = 4
const W = 8
const ALL = 15
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
var highways = []
var crossroads = []
var cells = []
var links = {}

var a = 31
var tile_size = 64  # tile size (in pixels)
var width = a  # width of map (in tiles)
var height = a # height of map (in tiles)
var zoom = 2
var half

# get a reference to the map for convenience
onready var map = $tileMap

func _ready():
	$camera2D.zoom = Vector2(zoom, zoom)
	$camera2D.position = map.map_to_world(Vector2(width/2, height/2*1.55))
	
	half = ceil(height / 2)
	
	tile_size = map.cell_size
	make_maze()
	init_cells()
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

func check_borders(cell_):
	return cell_.x < 0 || cell_.x >= width || cell_.y < 0 || cell_.y >= height

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

func init_cells():
	for x in range(width):
		for y in range(height):
			var cell = Global.Cell.new()
			cell.index = int(x * width + y)
			cell.grid = Vector2(x, y)
			cell.tile = map.get_cellv(cell.grid)
			cells.append(cell)
			
			if cell.tile != 15:
				links[cell.index] = []
				
				for neighbor in neighbors:
					if check_tile_include(cell.tile, neighbor):
						var cell_neighbor = cell.grid + neighbor
						
						if !check_borders(cell_neighbor):
							var index = int(cell_neighbor.x * width + cell_neighbor.y)
							links[cell.index].append(index)
				
				cell.neighbors.append_array(links[cell.index]) 
				
				if cell.neighbors.size() > 2:
					crossroads.append(cell.index)
					cell.crossroad = Global.primary_key.crossroad
					Global.primary_key.crossroad += 1

func find_deadends():
	for cell in cells:
		if cell.neighbors.size() == 1:
			deadends.append(cell.index)
	
	print("deadends: ",deadends.size())
	
	for deadend in deadends:
		var road = [deadend]
		var new_cell = cells[deadend].neighbors[0]
		make_road(new_cell,road)
		roads.append(road)
	
			#map.set_cellv(cells[cell_index].grid, 16)
	
	for crossroad in crossroads:
		for neighbor in cells[crossroad].neighbors:
			if cells[neighbor].crossroad != -1:
				var road = [crossroad,neighbor]
				make_road(neighbor,road)
				roads.append(road)
	
	for _i in roads.size():
		for cell_index in roads[_i]:
			cells[cell_index].roads.append(_i)			
	
	for crossroad in crossroads:
		for neighbor in cells[crossroad].neighbors:
			if cells[neighbor].roads.size() == 0:
				var road = [crossroad]
				make_road(neighbor,road)
				roads.append(road)
				map.set_cellv(cells[crossroad].grid, 16)
				map.set_cellv(cells[neighbor].grid, 16)#highways
	
	
	var first
	var end  
	
#	for road in roads:
#		if check_deadend(road) && road.size() == 4:
#			#first = road[0]
#
#
#			for _i in range(0, 3):#road.size()-1
#				map.set_cellv(cells[road[_i]].grid, 16)
	
#	for _i in roads.size():
#		if roads[_i].size() == 2:
#			for cell_index in roads[_i]:
#				map.set_cellv(cells[cell_index].grid, 16)

func make_road(begin,road):
	var new_cell = begin
	
	while cells[new_cell].neighbors.size() == 2:
		road.append(new_cell)
		
		for neighbor in cells[new_cell].neighbors:
			var index_f = road.find(neighbor)
			
			if index_f == -1:
				new_cell = neighbor
	
	new_cell = road[road.size()-1]
	
	for neighbor in cells[new_cell].neighbors:
			var index_f = road.find(neighbor)
			
			if index_f == -1:
				road.append(neighbor)

func tile_include_ways(tile):
	var reverse = 15 - tile
	var ways = [N,E,S,W]
	var reverse_ways = [W,S,E,N]
	var binary = []
	var bin = pow(2,ways.size()-1)
	var result = []
	
	for _i in ways.size():
		var flag = reverse >= bin
		
		if flag:
			reverse -= bin
			result.append(reverse_ways[_i])
		
		bin/=2
	return result

func check_tile_include(tile, neighbor):
	var included_ways = tile_include_ways(tile)
	var ways = [N,E,S,W]
	var index_f = included_ways.find(cell_walls[neighbor])
	var result = index_f != -1
	return result

func convert_grid(grid):
	return grid.x * width + grid.y 

func check_highways(road):
	var begin = road[0]
	var end = road[road.size()-1]
	return cells[begin].crossroad != -1 && cells[end].crossroad != -1

func check_deadend(road):
	var begin = road[0]
	var end = road[road.size()-1]
	return cells[begin].crossroad == -1 || cells[end].crossroad == -1
