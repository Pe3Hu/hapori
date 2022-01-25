extends Node


var main
var maze
var rng = RandomNumberGenerator.new()
var stamina_expense = {}
var primary_key = {}
var booty_list = {}
var SDIW = {}
var dangers = []

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
	primary_key.contestant  = 0

func init_booty():
	booty_list = {}
	booty_list["herb breed 0"] = ["extract"]
	booty_list["herb breed 1"] = ["extract"]
	booty_list["herb breed 2"] = ["extract"]

func init_sdiw():
	SDIW.short_keys = ["Strength","Dexterity","Intellect","Will"]
	SDIW.long_keys = ["capacity","replenishment","resistance","tension","outside","inside","reaction"]
	SDIW.list = {
		"Strength": #Сила
			{
				"capacity": "vitality",
				"replenishment": "fastness",
				"resistance": "overheat",
				"tension": "palingenesy",
				"outside": "savvy",
				"inside": "diversion",
				"reaction": "instinct"
			},
		"Dexterity": #Ловкость
			{
				"capacity": "plasticity",
				"replenishment": "elasticity",
				"resistance": "immediacy",
				"tension": "massage",
				"outside": "advertence",
				"inside": "postiche",
				"reaction": "reflex"
			},
		"Intellect": #Интеллект
			{
				"capacity": "erudition",
				"replenishment": "integrity",
				"resistance": "invention",
				"tension": "meditation",
				"outside": "observancy",
				"inside": "disinformation",
				"reaction": "prescience"
			},
		"Will": #Воля
			{
				"capacity": "mood",
				"replenishment": "sangfroid",
				"resistance": "fervor",
				"tension": "mantra",
				"outside": "prophecy",
				"inside": "bluff",
				"reaction": "intuition"
			},
		"capacity": #объем
			{
				"Strength": "vitality",
				"Dexterity": "plasticity",
				"Intellect": "erudition",
				"Will": "mood"
			},
		"resistance": #сопротивление
			{
				"Strength": "fastness",
				"Dexterity": "elasticity",
				"Intellect": "integrity",
				"Will": "sangfroid"
			},
		"tension": #натяжение
			{
				"Strength": "overheat",
				"Dexterity": "immediacy",
				"Intellect": "invention",
				"Will": "fervor"
			},
		"replenishment": #пополнение
			{
				"Strength": "palingenesy",
				"Dexterity": "massage",
				"Intellect": "meditation",
				"Will": "mantra"
			},
		"outside": #извне
			{
				"Strength": "savvy",
				"Dexterity": "advertence",
				"Intellect": "observancy",
				"Will": "prophecy"
			},
		"inside": #изнутри
			{
				"Strength": "diversion",
				"Dexterity": "postiche",
				"Intellect": "disinformation",
				"Will": "bluff"
			},
		"reaction": #реакция
			{
				"Strength": "instinct",
				"Dexterity": "reflex",
				"Intellect": "prescience",
				"Will": "intuition"
			}
		}
	SDIW.data_keys = {
		"vitality": 0, #живучесть
		"plasticity": 1, #гибкость
		"erudition": 2, #эрудиция
		"mood": 3, #настрой
		"fastness": 4, #стойкость
		"elasticity": 5, #упругость
		"integrity": 6, #целостность
		"sangfroid": 7, #выдержка
		"overheat": 8, #перегрев
		"immediacy": 9, #незамедлительность
		"invention": 10, #остроумие
		"fervor": 11, #рвение
		"palingenesy": 12, #регенерация
		"massage": 13, #массаж
		"meditation": 14, #медитация
		"mantra": 15, #мантра
		"savvy": 16, #отвлечение
		"advertence": 17, #смекалка
		"observancy": 18, #наблюдательность
		"prophecy": 19, #пророчество
		"diversion": 20, #отвлечение
		"postiche": 21, #притворство
		"disinformation": 22, #дезинформация
		"bluff": 23, #блеф
		"instinct": 24, #инстинкт
		"reflex": 25, #рефлекс
		"prescience": 26, #предвидение
		"intuition": 27 #интуиция
		}

func init_dangers():
	dangers = ["weak","middle","strong"]

func _ready():
	main = get_node("/root/main")
	maze = get_node("/root/main/maze")
	init_stamina_expense()
	init_primary_key()
	init_booty()
	init_sdiw()
	init_dangers()

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

class Sorter:
	static func sort(a, b):
		if a["value"] < b["value"]:
			return true
		return false
		
	static func unsort(a, b):
		if a["value"] > b["value"]:
			return true
		return false
