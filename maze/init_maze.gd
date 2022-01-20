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
var corner_neighbors = [
	Vector2(1, -1), 
	Vector2(1, 1),
	Vector2(-1, 1), 
	Vector2(-1, -1)
	]
var wall_neighbors = {
	N: Vector2(0, -1),
	E: Vector2(1, 0),
	S: Vector2(0, 1),
	W: Vector2(-1, 0)
	}
var deadends = []
var roads = []
var highways = []
var asphalts = []
var clearcoles = []
var crossroads = []
var cells = []
var links = {}
var coasts = []
var clusters = []

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
	
	init_maze()
	init_cells()
	init_deadends()
	init_highways()
	init_branchs()
	init_districts()
	init_coasts()
	init_clusters()

func init_maze():
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

func init_cells():
	for x in range(width):
		for y in range(height):
			var cell = Maze.Cell.new()
			cell.index = int(x * width + y)
			cell.grid = Vector2(x, y)
			cell.tile = map.get_cellv(cell.grid)
			cells.append(cell)
			
			if cell.tile != 15:
				links[cell.index] = []
			
			for neighbor in neighbors:
				var cell_neighbor = cell.grid + neighbor
				
				if !check_borders(cell_neighbor):
					var index = int(cell_neighbor.x * width + cell_neighbor.y)
					cell.all_neighbor_cells.append(index)
					
					if check_tile_include(cell.tile, neighbor) && cell.tile != 15:
						links[cell.index].append(index)
			
			if cell.tile != 15:
				cell.neighbors.append_array(links[cell.index]) 
			
			if cell.neighbors.size() > 2:
				crossroads.append(cell.index)
				cell.crossroad = Global.primary_key.crossroad
				Global.primary_key.crossroad += 1

func init_deadends():
	for cell in cells:
		if cell.neighbors.size() == 1:
			deadends.append(cell.index)
	
	for deadend in deadends:
		clearcoles.append(Global.primary_key.road)
		var road = [deadend]
		var new_cell = cells[deadend].neighbors[0]
		make_road(new_cell,road,"long")
	
	for crossroad in crossroads:
		for neighbor in cells[crossroad].neighbors:
			if cells[neighbor].crossroad != -1:
				asphalts.append(Global.primary_key.road)
				var road = [crossroad,neighbor]
				make_road(neighbor,road,"short")

	for crossroad in crossroads:
		for neighbor in cells[crossroad].neighbors:
			if cells[neighbor].roads.size() == 0:
				asphalts.append(Global.primary_key.road)
				var road = [crossroad]
				make_road(neighbor,road,"long")

func init_highways():
	var unvisited = set_unvisited_crossroad()
		
	while unvisited.size() > 0:
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, unvisited.size()-1)
	
		make_highway(unvisited[index_r])
		unvisited = set_unvisited_crossroad()

func init_branchs():
	var unvisited = []
	
	for clearcole in clearcoles:
		var begin = roads[clearcole].front()
		
		if cells[begin].highways.size() == 0:
			unvisited.append(clearcole)
	
	for _i in range(0,highways.size()):
		var highway = highways[_i]
		
		for clearcole in unvisited:
			if highway.cells.has(roads[clearcole].back()):
				highway.branchs.append(clearcole)
	
	unvisited = []
	
	for asphalt in asphalts:
		var flag = false
		
		for highway in highways:
			flag = flag || highway.roads.has(asphalt)
		
		if !flag:
			unvisited.append(asphalt)
	
	for asphalt in unvisited:
		for highway in highways:
			if highway.cells.has(roads[asphalt].back()):
				highway.branchs.append(asphalt)
				break
	
	for _i in range(highways.size()-1,-1,-1):
		var highway = highways[_i]
		
		if highway.roads.size() == 2 && highway.branchs.size() == 0:
			var cells_ = []
			var middle
			
			for road in highway.roads:
				if cells_.has(roads[road].front()):
					middle = roads[road].front()
				else:
					cells_.append(roads[road].front())
				if cells_.has(roads[road].back()):
					middle = roads[road].back()
				else:
					cells_.append(roads[road].back())
			
			var highways_ = []
			highways_.append_array(cells[middle].highways)
			highways_.erase(highway.index)
			var main_highway = highways_[0]
			
			for road in highway.roads:
				highways[main_highway].branchs.append(road)
			
			highways.remove(_i)

func init_districts():
	for cell in cells:
		if cell.crossroad != -1:
			var bans = []
			
			for neighbor in cell.all_neighbor_cells:
				if cells[neighbor].roads.size() == 0:
					cells[neighbor].city = cell.index
					cell.districts.append(neighbor)
					for district in cells[neighbor].all_neighbor_cells:
						bans.append(district)
			
			for neighbor in cell.all_neighbor_cells:
				if cells[neighbor].roads.size() != 0:
					for district in cells[neighbor].all_neighbor_cells:
						if cells[district].roads.size() == 0 && !bans.has(district):
							cells[district].city = cell.index
							cell.districts.append(district)

func init_coasts():
	var coasts_ = {}
	var coast_cells = {}
	
	for road_ in roads.size():
		for cell_ in roads[road_]:
			for neighbor_ in cells[cell_].all_neighbor_cells:
				var cell = cells[neighbor_]
				
				if cell.city == -1 && cell.roads.size() == 0 && cell.coast == -1:
					
					if !coasts_.keys().has(road_):
						coasts_[road_] = []
					
					coasts_[road_].append(cell.index)
					cell.coast = -2
	
	#add corners
	for cell in cells:
		if cell.coast == -1 && cell.roads.size() == 0 && cell.city == -1:
			var coast_ = -1
			var road_ = -1
			
			for corner_neighbor in corner_neighbors:
				var grid = cell.grid + corner_neighbor
				var index = convert_grid(grid)
				
				if cells[index].roads.size() > 0:
					road_ = cells[index].roads[0]
			
			for neighbor in cell.all_neighbor_cells:
				for coast in coasts_[road_].size():
					if coasts_[road_].has(cell.index):
						coast_ = coast
						
			coasts_[road_].append(cell.index)
			cell.coast = -2
	
	for cell in cells:
		cell.coast = -1
	
	for road_ in coasts_.keys(): 
		var options = []
		options.append_array(coasts_[road_])
		
		while options.size() > 0: 
			var cell_ = options.pop_back()
			var index_a = -1
			
			if !coast_cells.keys().has(road_):
				coast_cells[road_] = [[]]
			
			var coasts_arrays = coast_cells[road_]
			
			for neighbor in cells[cell_].all_neighbor_cells:
				for _i in coasts_arrays.size():
					if coasts_arrays[_i].has(neighbor):
						index_a = _i
			
			if index_a == -1:
				index_a = coasts_arrays.size()-1
				coasts_arrays.append([])
				
			coasts_arrays[index_a].append(cell_)
		
		for _i in coast_cells[road_].size()-1:
			for _j in range(_i+1,coast_cells[road_].size()-1,1):
				var flag = false
				
				for cell_ in coast_cells[road_][_j]:
					
					for neighbor in cells[cell_].all_neighbor_cells:
						if coast_cells[road_][_i].has(neighbor):
							flag = true
				
				if flag:
					coast_cells[road_][_i].append_array(coast_cells[road_][_j])
					coast_cells[road_][_j] = []
	
		for _i in range(coast_cells[road_].size()-1,-1,-1):
			if coast_cells[road_][_i].size() == 0:
				 coast_cells[road_].remove(_i)

	for road_ in coast_cells.keys():
		for _i in coast_cells[road_].size():
			var coast = Maze.Coast.new()
			coast.index = Global.primary_key.coast
			coast.road = road_
			coast.coast = _i
			coast.cells.append_array(coast_cells[road_][_i])
			
			for cell_ in coast_cells[road_][_i]:
				cells[cell_].coast = Global.primary_key.coast
				
			coasts.append(coast)
			Global.primary_key.coast += 1
	
func init_clusters():
	var clusters_ = []
	
	for coast in coasts:
		for cell_ in coast.cells:
			for neighbor in cells[cell_].all_neighbor_cells:
				if cells[neighbor].roads.size() == 0 && cells[neighbor].city == -1:
					if !coast.neighbors.has(cells[neighbor].coast) && cells[neighbor].coast != coast.index:
						coast.neighbors.append(cells[neighbor].coast)
						coasts[cells[neighbor].coast].neighbors.append(coast.index)
	
	for coast in coasts: 
		var index_c = -1
		var cluster = [coast.index]
		cluster.append_array(coast.neighbors)
		
		for coast_ in cluster:
			for _i in clusters_.size():
				if clusters_[_i].has(coast_):
					index_c = _i
					
		if index_c == -1:
			index_c = clusters_.size()-1
			clusters_.append([])
		
		for coast_ in cluster:
			if !clusters_[index_c].has(coast_):
				clusters_[index_c].append(coast_) 
	
	for _i in clusters_.size()-1:
		for _j in range(_i+1,clusters_.size()-1,1):
			var flag = false

			for coast in clusters_[_j]:
				for neighbor in coasts[coast].neighbors:
					if clusters_[_i].has(neighbor):
						flag = true

			if flag:
				clusters_[_i].append_array(clusters_[_j])
				clusters_[_j] = []

	for _i in range(clusters_.size()-1,-1,-1):
		if clusters_[_i].size() == 0:
			 clusters_.remove(_i)

	for coasts in clusters_:
		var cluster = Maze.Cluster.new()
		cluster.index = Global.primary_key.cluster
		cluster.coasts.append_array(coasts) 

		clusters.append(cluster)
		Global.primary_key.cluster += 1

func build_center(unvisited):
	map.set_cellv(Vector2(half, half), 0)
	var ways_ = [E,S,W,N]
	
	for _i in ways_.size():
		var grid = Vector2(half, half)
		var neighbor = neighbors[_i]
		grid = grid + neighbor
		map.set_cellv(grid, 15-ways_[(_i+1)%ways_.size()])
		connect_cells(grid, neighbor)
		
		for _j in half-2:
			grid = grid + neighbor
			connect_cells(grid, neighbor)
			
			if _j == step*2+1:
				unvisited.append(grid)
			
		grid =  Vector2(half, half) + neighbor *2
		connect_cells(grid, neighbors[(_i+3)%ways_.size()])
		grid = grid + neighbors[(_i+3)%ways_.size()]
		connect_cells(grid, neighbors[(_i+3)%ways_.size()])
		grid = grid + neighbors[(_i+3)%ways_.size()]
		connect_cells(grid, neighbors[(_i+2)%ways_.size()])
		grid = grid + neighbors[(_i+2)%ways_.size()]
		connect_cells(grid, neighbors[(_i+1)%ways_.size()])
		grid = grid + neighbors[(_i+1)%ways_.size()]
		connect_cells(grid, neighbors[(_i+1)%ways_.size()])
		
		for _j in 2:
			grid = Vector2(half, half) + neighbor * 3
			
			for _l in 3:
				connect_cells(grid, neighbors[(_i+1+_j*2)%ways_.size()])
				grid = grid + neighbors[(_i+1+_j*2)%ways_.size()]
				
		grid = Vector2(half, half)
		neighbor = neighbors[_i]
		grid = grid + neighbor
		remove_way(grid, ways_[(_i+3)%ways_.size()])
		grid = grid + neighbor
		remove_way(grid, ways_[(_i+1)%ways_.size()])

func make_road(begin,road,l):
	var new_cell = begin
	
	if l == "long":
		while cells[new_cell].neighbors.size() == 2:
			road.append(new_cell)
			
			for neighbor in cells[new_cell].neighbors:
				if !road.has(neighbor):
					new_cell = neighbor
		
		new_cell = road.back()
		
		for neighbor in cells[new_cell].neighbors:
				if !road.has(neighbor):
					road.append(neighbor)
	
	if !check_road_exist(road):
		roads.append(road)
	
		for cell_index in road:
			cells[cell_index].roads.append(Global.primary_key.road)
		Global.primary_key.road += 1

func set_unvisited_crossroad():
	var unvisited = []
	
	for crossroad in crossroads:
		var counter = 0
		
		for neighbor in cells[crossroad].neighbors:
			if cells[neighbor].highways.size() != 1:
				counter += 1
		
		if counter > 1:
			unvisited.append(crossroad)
	
	return unvisited

func make_highway(begin):
	var obj = {}
	obj.highway = []
	obj.cells = []
	obj.crossroads = []
	obj.begins = [begin]
	obj.asphalt_options = []
	obj.clearcole_options = []
	obj.asphalt_begins = []
	obj.clearcole_begins = []
	
	while obj.asphalt_options.size() > 0 || obj.highway.size() == 0:
		find_road_to_highway(obj)
		
		if obj.asphalt_options.size() > 0:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, obj.asphalt_options.size()-1)
			var road_r = obj.asphalt_options[index_r]
			obj.highway.append(road_r)
			obj.cells.append_array(roads[road_r])
			var old_begin = obj.asphalt_begins[index_r]
			
			if obj.begins.size() > 1:
				obj.begins.erase(old_begin)
			
			if roads[road_r].front() == old_begin:
				obj.begins.append(roads[road_r].back()) 
			else:
				if roads[road_r].back() == old_begin:
					obj.begins.append(roads[road_r].front()) 
			
			for begin in obj.begins:
				if !obj.crossroads.has(begin):
					obj.crossroads.append(begin)
		else:
			if obj.clearcole_options.size() > 0:
				Global.rng.randomize()
				var index_r = Global.rng.randi_range(0, obj.clearcole_options.size()-1)
				var road_r = obj.clearcole_options[index_r]
				obj.highway.append(road_r)
				obj.cells.append_array(roads[road_r])
				var old_begin = obj.clearcole_begins[index_r]
				
				if obj.highway.size() > 1:
					for _i in range(obj.clearcole_begins.size()-1,-1,-1):
						if obj.clearcole_begins[_i] == old_begin:
							obj.clearcole_begins.remove(_i)
							obj.clearcole_options.remove(_i)
				else:
					var index_f = obj.clearcole_options.find(road_r)
					obj.clearcole_begins.remove(index_f)
					obj.clearcole_options.remove(index_f)
					
				if obj.clearcole_options.size() > 0:
					Global.rng.randomize()
					index_r = Global.rng.randi_range(0, obj.clearcole_options.size()-1)
					road_r = obj.clearcole_options[index_r]
					obj.highway.append(road_r)
					obj.cells.append_array(roads[road_r])
	
	for cell_index in obj.cells:
		cells[cell_index].highways.append(Global.primary_key.highway)
	
	var highway = Maze.Highway.new()
	highway.index = Global.primary_key.highway
	highway.roads = obj.highway
	highway.crossroads = obj.crossroads
	highway.cells = obj.cells
	
	highways.append(highway)
	Global.primary_key.highway += 1

func check_center(x_,y_):
	var size = step
	var x = ( x_ <= half + size && x_ >= half - size )
	var y = ( y_ <= half + size && y_ >= half - size )
	return x&&y

func check_borders(cell_):
	return cell_.x < 0 || cell_.x >= width || cell_.y < 0 || cell_.y >= height

func check_neighbors(grid, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in steped_walls.keys():
		if grid + n in unvisited:
			list.append(grid + n)
	return list

func check_tile_include(tile, neighbor):
	var included_ways = tile_include_ways(tile)
	return included_ways.has(cell_walls[neighbor])

func check_highways(road):
	return cells[road.front()].crossroad != -1 && cells[road.back()].crossroad != -1

func check_deadend(road):
	return cells[road.front()].crossroad == -1 || cells[road.back()].crossroad == -1

func check_road_exist(road_):
	var flag = false
	
	for road in roads:
		var index_f = road_.find(road.front())
		
		if index_f != -1:
			index_f = road_.find(road.back())
		
			if index_f != -1:
				flag = true
	return flag

func convert_grid(grid):
	return grid.x * width + grid.y 

func connect_cells(grid, neighbor):
	if map.get_cellv(grid) & cell_walls[neighbor]:
		var walls = map.get_cellv(grid) - cell_walls[neighbor]
		var n_walls = map.get_cellv(grid+neighbor) - cell_walls[-neighbor]
		map.set_cellv(grid, walls)
		map.set_cellv(grid+neighbor, n_walls)

func remove_way(grid, way):
	var neighbor = wall_neighbors[way]
	var tile = map.get_cellv(grid)
	
	if check_tile_include(tile, neighbor):
		var included_ways = tile_include_ways(tile)
		included_ways.erase(way) 
		tile = 15
		for included_way in included_ways:
			tile -= included_way
		map.set_cellv(grid, tile)

func find_road_to_highway(obj):
	obj.clearcole_options = []
	obj.asphalt_options = []
	obj.asphalt_begins = []
	obj.clearcole_begins = []
	
	for begin in obj.begins:
		for neighbor in cells[begin].neighbors:
			if (cells[neighbor].highways.size() == 0 && cells[neighbor].crossroad == -1 ) || cells[neighbor].crossroad != -1:
				for road in cells[neighbor].roads:
					if !obj.highway.has(road) && roads[road].has(begin):
						var counter = 0
						
						if obj.crossroads.has(roads[road].front()):
							counter += 1
						if obj.crossroads.has(roads[road].back()):
							counter += 1
						if counter < 2:
							if asphalts.has(road):
								obj.asphalt_options.append(road)
								obj.asphalt_begins.append(begin)
							if clearcoles.has(road):
								obj.clearcole_options.append(road)
								obj.clearcole_begins.append(begin)

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

func get_highway_index(road):
	var index = -1
	
	for highway in highways:
		if highway.roads.has(road):
			index = highway.index
		
		if highway.branchs.has(road):
			index = highway.index
		
	return index

func color_highways():
	var color = 16 
	for highway in highways:
		for branch in highway.branchs:
			for cell_index in roads[branch]:
				if cells[cell_index].crossroad == -1:
					map.set_cellv(cells[cell_index].grid, color)

		if highway.roads.size() != -1:
			for road in highway.roads:
				for cell_index in roads[road]:
					if cells[cell_index].crossroad == -1:
						map.set_cellv(cells[cell_index].grid, color)
		color += 2

func color_coasts():
	for coast in coasts:
		var index = get_highway_index(coast.road)
		var color = 16 + 2 * index

		for cell_ in coast.cells:
			var cell = cells[cell_]
			map.set_cellv(cell.grid, color)

func color_clusters():
	var color = 16
	
	for cluster_ in clusters:
		for coast_ in cluster_.coasts:
			for cell_ in coasts[coast_].cells:
				var cell = cells[cell_]
				map.set_cellv(cell.grid, color)
		color += 1
		
		if color == 30:
			color = 16
