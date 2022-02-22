extends Control

func init_map():
	Global.object.map = {}
	Global.object.map.graph = {
		"0": ["1","2","3","4","5","6"],
		"1": ["0","2","6"],
		"2": ["0","1","3"],
		"3": ["0","2","4"],
		"4": ["0","3","5"],
		"5": ["0","4","6"],
		"6": ["0","1","5"]
	}
	
	Global.object.map.tiles = []
	Global.object.map.n = 7
	
	for _i in Global.object.map.n:
		var tile = Global.Tile.new()
		var obj = {}
		obj.index = _i
		
		if _i > 0:
			obj.type = "meadow"
			obj.breed = "herb breed "+str((_i-1)%3)
		else:
			obj.type = "city"
		
		tile.set_(obj)
		Global.object.map.tiles.append(tile)

func init_alternatives():
	var indexs = 4
	
	for _i in indexs:
		var alternative = Member.Alternative.new()
		alternative.set_index(_i)
		Global.array.alternatives.append(alternative)

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
					if !sequences_[i-1][_i].has(_j): 
						var sequence = []
						sequence.append_array(sequences_[i-1][_i])
						sequence.append(_j)
						sequences_[i].append(sequence)
		
		i += 1
	
	Global.array.sequences.append_array(sequences_[n-1])
	
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
					Global.array.verges.append(verges_)
	
	Global.array.verges.shuffle()
	
	for _i in criterions.limit.success:
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.array.sequences.size()-1)
		var sequence = Global.array.sequences[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, Global.array.verges.size()-1)
		var verges_ = Global.array.verges[index_r]
		
		var recipe = Loot.Recipe.new()
		recipe.set_extract(sequence, verges_)
		recipe.index = Global.list.primary_key.recipe
		Global.array.recipes.append(recipe)
		Global.list.primary_key.recipe += 1

func init_souls():
	#var n = 3
	var vocations = {
		"getter": 10,
		"artificer": 8
	}
	
	for vocation in vocations.keys():
		for _i in vocations[vocation]:
			var soul = Member.Soul.new()
			soul.vocations.append(vocation)  
			var obj = {}
			obj.index = Global.list.primary_key.soul
			obj.parent = self
			soul.init(obj)
			Global.array.souls.append(soul)
			Global.list.primary_key.soul += 1

func _ready():
	init_map()
	init_alternatives()
	init_recipes()
	init_souls()
	Global.flag.ready = true

func _process(delta):
	if Global.flag.ready:
		for soul in Global.array.souls:
			soul.time_flow(delta)
		
		Global.object.rialto.time_flow(delta)

