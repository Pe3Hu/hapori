extends Control

var souls
var rialto
var fibonacci
var alternatives
var map 
var items = []
var lots = []
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

func init_souls():
	var n = 3
	souls = []
	var vocations = {
		"getter": 8,
		"artificer": 3
	}
	var index = 0
	
	for vocation in vocations.keys():
		for _i in vocations[vocation]:
			var soul = Global.Soul.new()
			soul.vocations.append(vocation)  
			var obj = {}
			obj.index = index
			obj.parent = self
			soul.init(obj)
			souls.append(soul)
			index += 1

func _ready():
	init_map()
	init_fibonacci_rialto()
	init_alternatives()
	init_souls()
	ready = true
	
func _process(delta):
	if ready:
		for soul in souls:
			soul.time_flow(delta)
			
		rialto.time_flow(delta)
