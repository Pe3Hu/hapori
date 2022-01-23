extends Node2D

onready var map = $map
var a :int = 9
var width  = a  # width of map (in tiles)
var height = a # height of map (in tiles)
var center
var around_center = 0

var square_neighbors = [
	Vector2(0, -1),
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0)
	]
var octagon_neighbors = [
	Vector2(0, -1),
	Vector2(1, -1),
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, -1)
	]
var sectors = []
var colors = [0,1,2,3]

func _ready():
	center = ceil(height / 2)
	
	init_sectors()
	
func init_sectors():
	for x in width:
		sectors.append([])
		
		for y in height:
			var sector = Reactor.Sector.new()
			sector.index = Global.primary_key.sector
			sector.parity = (x+y)%2
			sector.grid = Vector2(x, y)
			sector.edges = (sector.parity +1)*4
			
			if sector.parity == 1:
				sector.neighbors.append_array(square_neighbors)
			else:
				sector.neighbors.append_array(octagon_neighbors)
				
			sectors[x].append(sector)
			
			Global.primary_key.sector += 1
	
	for sectors_ in sectors:
		for sector_ in sectors_:
			for neighbor_ in sector_.neighbors:
				var neighbor  = neighbor_ + sector_.grid
				
				if !check_borders(neighbor):
					var index_s = convert_grid(neighbor)
					sector_.all_neighbors.append(index_s)
					
					if square_neighbors.has(neighbor_):
						sector_.ring_neighbors.append(index_s)
	
	sectors_around_center()
#	var grid = convert_index(13)#13,43,37,67
#	map.set_cellv(Vector2(grid.x, grid.y), 1)
	
	paint_sectors()

	for sectors_ in sectors:
		for sector_ in sectors_:
			if sector_.visibility&& sector_.color != -1:
				var tile = sector_.parity*4+sector_.color
				map.set_cellv(Vector2(sector_.grid.x, sector_.grid.y), tile)

func sectors_around_center():
	sectors[center][center].ring = 0
	
	var visited = [sectors[center][center].index]
	
	for ring_ in range(1,center+1,1):
		var new_ring = []
		
		for sectors_ in sectors:
			for sector_ in sectors_:
				for neighbor_ in sector_.ring_neighbors:
					
					if visited.has(neighbor_) && sector_.ring == -1:
						sector_.ring = ring_
						new_ring.append(sector_.index)
						around_center += 1
		
		visited.append_array(new_ring)
	
	for sectors_ in sectors:
		for sector_ in sectors_:
			if sector_.ring != -1:
				for neighbor_ in sector_.all_neighbors:
					var grid = convert_index(neighbor_)
					
					if sectors[grid.x][grid.y].ring != -1:
						sector_.center_neighbors.append(neighbor_)
				
				sector_.visibility = true

func paint_sectors():
	Global.rng.randomize()
	var index_r = Global.rng.randi_range(0, colors.size()-1)
	sectors[center][center].color = colors[index_r] 
	
	var subring = 0
	var counter = 0
	var unpainted = []
	
	while counter < around_center:
		counter += 1
		var grid
		
		if unpainted.size() == 0:
			subring += 1
			var options = []
			var min_ring = center
			
			for sectors_ in sectors:
				for sector_ in sectors_: 
					if sector_.color == -1:
						var painted_neighbors = 0
						
						for neighbor_ in sector_.all_neighbors:
							grid = convert_index(neighbor_)
							
							if sectors[grid.x][grid.y].color != -1:
								painted_neighbors += 1
						
						if painted_neighbors > 1 || ( subring == 1 && sector_.ring == 1 ):
							options.append(sector_)
							if sector_.ring < min_ring && sector_.ring > 0:
								min_ring = sector_.ring
			
			for option in options:
				if option.ring == min_ring:
					unpainted.append(option.index)
			print(min_ring,"??",options.size(),">",unpainted.size())
		
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, unpainted.size()-1)
		grid = convert_index(unpainted[index_r])
		unpainted.remove(index_r)
		var sector_ = sectors[grid.x][grid.y]
		var free_colors = []
		free_colors.append_array(colors)
		
		for neighbor_ in sector_.center_neighbors:
			grid = convert_index(neighbor_)
			var index_f = free_colors.find(sectors[grid.x][grid.y].color)
			#print(neighbor_," @ ",sectors[grid.x][grid.y].color)
			if index_f != -1:
				free_colors.remove(index_f)
		
		print(counter,free_colors)
		if free_colors.size() > 0:
			Global.rng.randomize()
			index_r = Global.rng.randi_range(0, free_colors.size()-1)
			sector_.color = free_colors[index_r]
			print(sector_.index," FILL ",free_colors[index_r] )
			print(unpainted)
		else:
			print("color error")
	
#	for sectors_ in sectors:
#		for sector_ in sectors_:
#			if sector_.color != -1:
#				for neighbor_ in sector_.center_neighbors:
#					var grid = convert_index(neighbor_)
#
#					if sectors[grid.x][grid.y].color == -1:
#						sector_.center_neighbors.append(neighbor_)
	

func check_borders(grid):
	return grid.x < 0 || grid.x >= width || grid.y < 0 || grid.y >= height

func convert_grid(grid):
	return int(grid.x * width + grid.y)

func convert_index(index):
	var x = ceil(index/width)
	var y = index%width
	return Vector2(x,y)
		
