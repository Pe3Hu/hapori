extends Control

var soul
var rialto
var map 
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
			obj.breed = "herb "+str((_i-1)%3)
		else:
			obj.type = "city"
		
		tile.set_type(obj)
		map.tiles.append(tile)

func init_rialto():
	rialto = Global.Rialto.new()

func init_soul():
	soul = Global.Soul.new()
	soul.current.vocation = "herbal"
	soul.set_parent(self) 
	soul.set_duty_cycle()
		
		
	print(soul.duty_cycle)

func _ready():
	init_map()
	init_rialto()
	init_soul()
	ready = true
	
func _process(delta):
	if ready:
		if soul.duty_cycle.size() > 0:
			if soul.temp.time_cost <= 0:
				soul.what_should_i_do()
				print(soul.temp.task, "  ", soul.temp.time_cost)
		soul.temp.time_cost -= delta
