extends Node


var main
var maze
var rng = RandomNumberGenerator.new()
var stamina_expense = {}
var primary_key = {}
var booty_list = {}

func init_stamina_expense():
	stamina_expense.routine = -2
	stamina_expense.trip = -8
	stamina_expense.espial = -32
	stamina_expense.in_stasis = 0
	stamina_expense.after_stasis = -16
	stamina_expense.rest = 64

func init_primary_key():
	primary_key.item = 0
	primary_key.lot = 0
	primary_key.soul = 0
	primary_key.recipe = 0
	primary_key.road = 0
	primary_key.highway = 0
	primary_key.crossroad = 0
	primary_key.coast = 0
	primary_key.cluster = 0
	primary_key.booty = 0
	primary_key.sector = 0

func init_booty():
	booty_list = {}
	booty_list["herb breed 0"] = ["extract"]
	booty_list["herb breed 1"] = ["extract"]
	booty_list["herb breed 2"] = ["extract"]

func _ready():
	main = get_node("/root/main")
	maze = get_node("/root/main/maze")
	init_stamina_expense()
	init_primary_key()
	init_booty()

func triangle_check(verges, l):
	var flag = l > verges[0] + verges[1] + verges[2]
	
	if flag:
		flag = verges[0] > 0 && verges[1] > 0 && verges[2] > 0
		
		if flag:
			flag = flag && verges[0] + verges[1] > verges[2]
			flag = flag && verges[1] + verges[2] > verges[0]
			flag = flag && verges[2] + verges[0] > verges[1]
	
	return flag

class Tile: 
	var type
	var index
	var landscape = {}

	func set_(landscape_):
		index = landscape_.index
		type = landscape_.type
		
		match type:
			"meadow":
				init_seeds(landscape_.breed)
				burst_into_blossom()

	func init_seeds(breed_):
		landscape.grade = 1
		landscape.n = 12
		landscape.current_herb = 0 
		landscape.total_herb = landscape.n*3
		landscape.seeds = []
		landscape.available = []
		landscape.sourdough = false
		landscape.breed = breed_
		
		for _i in landscape.n:
			landscape.seeds.append([])
			landscape.available.append(_i)
			
			for _j in landscape.n:
				landscape.seeds[_i].append(0)

	func burst_into_blossom():
		if !landscape.sourdough:
			sprout(landscape.grade+1)
		
		while landscape.current_herb < landscape.total_herb:
			sprout(landscape.grade)

	func sprout(grade_):
		Global.rng.randomize()
		var _i = Global.rng.randi_range(0, landscape.n-1)
		var _j = Global.rng.randi_range(0, landscape.n-1)
		
		while landscape.seeds[_i][_j] != 0:
			_i += 1
			
			if _i == landscape.n:
				_i = 0
				_j += 1
			
			if _j == landscape.n:
				_j = 0
		
		landscape.seeds[_i][_j] = grade_
		landscape.current_herb += pow(grade_, 2)

	func pluck(_i,_j):
		landscape.current_herb -= pow(landscape.seeds[_i][_j], 2)
		landscape.seeds[_i][_j] = 0
