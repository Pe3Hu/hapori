extends Node


var rng = RandomNumberGenerator.new()

class Soul:
	var vocation = []
	var current = {
		vocation: null
	}
	var duty_cycle = []
	var temp = {}
	var parent
	var bag = {}
	
	func init_bag():
		bag.max_weight = 100
		bag.curret_weight = 0
		bag.max_cargo = 10
		bag.cargo = {}
	
	
	func set_parent(_parent):
		parent = _parent
		init_bag()
	
	func set_duty_cycle():
		duty_cycle = []
		
		match current.vocation:
			"herbal":
				temp.time_cost = 0
				duty_cycle.append("select prey")
				duty_cycle.append("select wetland")
				duty_cycle.append("wetland trip")
				duty_cycle.append("wetland payment")
				duty_cycle.append("prey espial")
				duty_cycle.append("return trip")
				duty_cycle.append("prey sell")
	
	func what_should_i_do():
		temp.task = duty_cycle.pop_front()
		
		match temp.task:
			"select prey":
				temp.time_cost = 0.1
				find_best_prey()
			"select wetland":
				temp.time_cost = 0.1
				find_best_wetland()
			"wetland trip":
				temp.time_cost = 0.5
			"wetland payment":
				temp.time_cost = 0.1
			"prey espial":
				prey_espial()
			"return trip":
				temp.time_cost = 0.5
			"prey sell":
				temp.time_cost = 0.1

	func find_best_prey():
		temp.best_prey = parent.rialto.sorted_prices[0]
	
	func find_best_wetland():
		var options = []
		
		for tile in parent.map.tiles:
			if tile.type == "meadow":
				if tile.obj.breed == temp.best_prey:
					options.append(tile)
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, options.size()-1)
		temp.best_wetland = options[index_r]
	
	func prey_espial():
		var cols_count = 1
		var seeds = temp.best_wetland.obj.seeds
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, seeds.size()-1)
		var cols_begin = index_r
		var hitch_on_move = 0.01
		var hitch_on_overlook = 0.03
		var hitch_on_sprout = 0.05
		var move_time = 0
		var overlook_time = 0
		var sprout_time = 0
		
		for _c in cols_count:
			var _i = (cols_begin+_c)%seeds.size()
			
			for _j in seeds[_i].size():
				if seeds[_i][_j] != 0:
					sprout_time += pow(hitch_on_sprout,seeds[_i][_j])
					
					var cargo = {}
					cargo.where = temp.best_wetland.type
					cargo.what = temp.best_wetland.obj.breed
					cargo.grade = seeds[_i][_j]
					add_to_bag(cargo)
					temp.best_wetland.pluck(_i,_j)
		
		move_time = cols_count * temp.best_wetland.obj.n * hitch_on_move
		overlook_time = cols_count * temp.best_wetland.obj.n * hitch_on_overlook
		temp.time_cost = move_time + overlook_time + sprout_time
		print(bag.cargo)
		
	func add_to_bag(cargo):
		var index_f = bag.cargo.keys().find(cargo.what)
		
		if index_f == -1:
			bag.cargo[cargo.what] = {}
		
		index_f = bag.cargo[cargo.what].keys().find(cargo.grade)
		
		if index_f == -1:
			bag.cargo[cargo.what][cargo.grade] = 0
		
		bag.cargo[cargo.what][cargo.grade] += 1

class Tile: 
	var type
	var index
	var obj = {}
	
	func set_type(obj):
		type = obj.type
		index = obj.index
		
		match type:
			"meadow":
				init_seeds(obj.breed)
				burst_into_blossom()
	
	func init_seeds(_breed):
		obj.grade = 1
		obj.n = 10
		obj.current_herb = 0 
		obj.total_herb = obj.n*2
		obj.seeds = []
		obj.sourdough = false
		obj.breed = _breed
		
		for _i in obj.n:
			obj.seeds.append([])
			for _j in obj.n:
				obj.seeds[_i].append(0)
				
	func burst_into_blossom():
		if !obj.sourdough:
			sprout(obj.grade+1)
		
		while obj.current_herb < obj.total_herb:
			sprout(obj.grade)
	
	func sprout(_grade):
		Global.rng.randomize()
		var _i = Global.rng.randi_range(0, obj.n-1)
		var _j = Global.rng.randi_range(0, obj.n-1)
		
		while obj.seeds[_i][_j] != 0:
			_i += 1
			
			if _i == obj.n:
				_i = 0
				_j += 1
			
			if _j == obj.n:
				_j = 0
		
		obj.seeds[_i][_j] = _grade
		obj.current_herb += pow(_grade, 2)
	
	func pluck(_i,_j):
		obj.current_herb -= pow(obj.seeds[_i][_j], 2)
		obj.seeds[_i][_j] = 0

class Rialto:
	var prices = {
		"herb 0": 1,
		"herb 1": 2,
		"herb 2": 3
	}
	var sorted_prices = ["herb 2","herb 1","herb 0"]
