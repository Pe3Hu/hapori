extends Control

var souls
var rialto
var fibonacci
var alternatives
var map 
var items = []
var lots = []
var sequences = []
var verges = []
var recipes = []
var ready = false

func init_map():
	map = {}
	map.graph = {
		"0": ["1","2","3","4","5","6"],
		"1": ["0","2","6"],
		"2": ["0","1","3"],
		"3": ["0","2","4"],
		"4": ["0","3","5"],
		"5": ["0","4","6"],
		"6": ["0","1","5"]
	}
	
	map.tiles = []
	map.n = 7
	
	for _i in map.n:
		var tile = Global.Tile.new()
		var obj = {}
		obj.index = _i
		
		if _i > 0:
			obj.type = "meadow"
			obj.breed = "herb breed "+str((_i-1)%3)
		else:
			obj.type = "city"
		
		tile.set_(obj)
		map.tiles.append(tile)

func init_fibonacci_rialto():
	fibonacci = Global.Fibonacci.new()
	rialto = Global.Rialto.new()

func init_alternatives():
	var indexs = 4
	alternatives = []
	
	for _i in indexs:
		var alternative = Global.Alternative.new()
		alternative.set_index(_i)
		alternatives.append(alternative)

func init_recipes():
	var sequences_ = []
	var n = 3
	var i = 0
	
	while i < n:
		sequences_.append([])
		
		if sequences_.size() == 1:
			for _i in n:
				sequences_[i].append([_i])
		else:
			for _i in sequences_[i-1].size():
				for _j in n:
					var index_f = sequences_[i-1][_i].find(_j)
					
					if index_f == -1: 
						var sequence = []
						sequence.append_array(sequences_[i-1][_i])
						sequence.append(_j)
						sequences_[i].append(sequence)
		
		i += 1
	
	sequences.append_array(sequences_[n-1])
	
	var criterions = {}
	criterions.n = 20
	criterions.limit = {}
	criterions.limit.l = 32
	criterions.limit.success = 18
	
	for _a in criterions.n:
		for _b in criterions.n:
			for _c in criterions.n:
				var a = _a + 1
				var b = a + _b
				var c = b + _c
				var verges_ = [a,b,c]
				
				if Global.triangle_check(verges_, criterions.limit.l):
					verges.append(verges_)
	
	verges.shuffle()
	
	for _i in criterions.limit.success:
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, sequences.size()-1)
		var sequence = sequences[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, verges.size()-1)
		var verges_ = verges[index_r]
		
		var recipe = Global.Recipe.new()
		recipe.set_extract(sequence, verges_)
		recipe.index = Global.primary_key.recipe
		recipes.append(recipe)
		Global.primary_key.recipe += 1
	
#	for recipe in recipes:
#		print(recipe.index,recipe.extract,recipe.sum)

func init_souls():
	var n = 3
	souls = []
	var vocations = {
		"getter": 0,
		"artificer": 1
	}
	
	for vocation in vocations.keys():
		for _i in vocations[vocation]:
			var soul = Global.Soul.new()
			soul.vocations.append(vocation)  
			var obj = {}
			obj.index = Global.primary_key.soul
			obj.parent = self
			soul.init(obj)
			souls.append(soul)
			Global.primary_key.soul += 1

func _ready():
	init_map()
	init_fibonacci_rialto()
	init_alternatives()
	init_recipes()
	init_souls()
	ready = true
	
func _process(delta):
	if ready:
		for soul in souls:
			soul.time_flow(delta)
			
		rialto.time_flow(delta)
