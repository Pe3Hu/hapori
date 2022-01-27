extends Node


var root
var main
var maze
var battleground
var rng = RandomNumberGenerator.new()
var stamina_expense = {}
var primary_key = {}
var booty_list = {}
var SDIW = {}
var dangers = []
var ability_help = {}
var abilitys = []
var tempers = []

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
	primary_key.contestant = 0
	primary_key.ability = 0

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
	dangers = ["Weak","Middle","Strong"]
	tempers = {
		"Coward": {
			"Attack": 1,
			"Defense": 5-5
			},
		"Cynic": {
			"Attack": 3,
			"Defense": 3-3
			},
		"Lionheart": {
			"Attack": 5,
			"Defense": 1-1
			}
		}

func init_ability_help():
	ability_help.abbreviation = ["A","B","C","D","E","F","G","H","I","J","L","M","O","P","Q","R","S","T","V","W","Y"]
	ability_help.list = {
		"Whereby": ["Jab","Incision","Crush","Wave","Explosion"],#Укол Разрез Раcкол Волна Взрыв 
		"Wherewith": ["Glide","Parry","Block","Let","Teleport","Yoke"],#Скольжение Парирование Блок Барьер Блинк Захват
		"How": ["Distinct","Volley","Queue","Aim","Flow"],#Одиночный Самонаведение Луч Залп Очередь
		"What": ["Rune","Seal","Hex","Observance","Massif"]#Руна Печать Заклинание Ритуал Массив
		}
	ability_help.time = {
		"J": {
			"min": 1,
			"max": 2
			},
		"I": {
			"min": 2,
			"max": 4
			},
		"С": {
			"min": 3,
			"max": 6
			},
		"W": {
			"min": 4,
			"max": 8
			},
		"E": {
			"min": 5,
			"max": 10
			},
		"D": {
			"min": 1,
			"max": 1
			},
		"A": {
			"min": 3,
			"max": 4
			},
		"F": {
			"min": 4,
			"max": 5
			},
		"V": {
			"min": 5,
			"max": 7
			},
		"Q": {
			"min": 5,
			"max": 7
			},
		"G": {
			"min": 1,
			"max": 1
			},
		"P": {
			"min": 2,
			"max": 3
			},
		"B": {
			"min": 3,
			"max": 5
			},
		"L": {
			"min": 5,
			"max": 8
			},
		"T": {
			"min": 6,
			"max": 7
			},
		"Y": {
			"min": 4,
			"max": 6
			},
		"R": {
			"min": 1,
			"max": 3
			},
		"S": {
			"min": 2,
			"max": 6
			},
		"H": {
			"min": 4,
			"max": 12
			},
		"O": {
			"min": 8,
			"max": 24
			},
		"M": {
			"min": 16,
			"max": 48
			}
		}
	ability_help.cargo = {
		"J": {
			"min": 1,
			"max": 3
			},
		"I": {
			"min": 2,
			"max": 4
			},
		"С": {
			"min": 3,
			"max": 5
			},
		"W": {
			"min": 5,
			"max": 7
			},
		"E": {
			"min": 4,
			"max": 6
			},
		"D": {
			"min": 1,
			"max": 1
			},
		"A": {
			"min": 2,
			"max": 10
			},
		"F": {
			"min": 3,
			"max": 10
			},
		"V": {
			"min": 5,
			"max": 10
			},
		"Q": {
			"min": 5,
			"max": 10
			},
		"G": {
			"min": 1,
			"max": 10
			},
		"P": {
			"min": 1,
			"max": 10
			},
		"B": {
			"min": 1,
			"max": 10
			},
		"L": {
			"min": 1,
			"max": 10
			},
		"T": {
			"min": 1,
			"max": 10
			},
		"Y": {
			"min": 1,
			"max": 10
			},
		"R": {
			"min": 1,
			"max": 2
			},
		"S": {
			"min": 2,
			"max": 4
			},
		"H": {
			"min": 3,
			"max": 6
			},
		"O": {
			"min": 4,
			"max": 8
			},
		"M": {
			"min": 5,
			"max": 10
			}
		}
	
	ability_help.actions = ["Attack","Defense"]
	ability_help.basic_abilitys = {}
	
	for action in ability_help.actions:
		ability_help.basic_abilitys[action] = []
		var wherebys = []
		var wherewiths = []
		
		match action:
			"Attack":
				wherebys = ["Jab","Incision","Crush"]
			"Defense":
				wherewiths = ["Glide","Block"]
	
		for whereby in wherebys:
			var obj = {
				"Index": Global.primary_key.ability,
				"Name": "Basic "+whereby,
				"Action": action,
				"Whereby": whereby,
				"How": "Distinct",
				"What": "Hex"
			}
			var ability = Battleground.Ability.new(obj)
			abilitys.append(ability)
			ability_help.basic_abilitys[action].append(Global.primary_key.ability)
			Global.primary_key.ability += 1
	
		for wherewith in wherewiths:
			var obj = {
				"Index": Global.primary_key.ability,
				"Name": "Basic "+wherewith,
				"Action": action,
				"Wherewith": wherewith,
				"What": "Hex"
			}
			var ability = Battleground.Ability.new(obj)
			abilitys.append(ability)
			ability_help.basic_abilitys[action].append(Global.primary_key.ability)
			Global.primary_key.ability += 1

func _ready():
	root = get_node("/root")
	main = get_node("/root/main")
	maze = get_node("/root/main/maze")
	battleground = root.get_node("battleground")
	
	init_stamina_expense()
	init_primary_key()
	init_booty()
	init_sdiw()
	init_dangers()
	init_ability_help()

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
