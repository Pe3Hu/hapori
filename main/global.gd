extends Node


var rng = RandomNumberGenerator.new()
var array = {}
var list = {}
var node = {}
var object = {}
var flag = {}

func init_stamina_expense():
	list.stamina_expense = {}
	list.stamina_expense.routine = -2
	list.stamina_expense.trip = -8
	list.stamina_expense.espial = -32
	list.stamina_expense.in_stasis = 0
	list.stamina_expense.after_stasis = -16
	list.stamina_expense.rest = 64

func init_primary_key():
	list.primary_key = {}
	list.primary_key.item = 0
	list.primary_key.lot = 0
	list.primary_key.soul = 0
	list.primary_key.recipe = 0
	list.primary_key.road = 0
	list.primary_key.highway = 0
	list.primary_key.crossroad = 0
	list.primary_key.coast = 0
	list.primary_key.cluster = 0
	list.primary_key.booty = 0
	list.primary_key.sector = 0
	list.primary_key.contestant = 0
	list.primary_key.ability = 0
	list.primary_key.module = 0

func init_sdiw():
	list.SDIW = {}
	list.SDIW.short_keys = ["Strength","Dexterity","Intellect","Will"]
	list.SDIW.long_keys = ["capacity","replenishment","resistance","tension","outside","inside","reaction"]
	list.SDIW.list = {
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
	list.SDIW.data_indexs = {
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
	list.SDIW.data_keys = [
		"vitality","plasticity","erudition","mood","fastness","elasticity","integrity",
		"sangfroid","overheat","immediacy","invention","fervor","palingenesy","massage",
		"meditation","mantra","savvy","advertence","observancy","prophecy","diversion",
		"postiche","disinformation","bluff","instinct","reflex","prescience","intuition"
		]
	list.SDIW.primes = 3
	list.SDIW.wingmans = 4

func init_ability_help():
	list.ability_help = {}
	list.ability_help.abbreviation = ["A","B","C","D","E","F","G","H","I","J","L","M","O","P","Q","R","S","T","V","W","Y"]
	list.ability_help.list = {
		"Whereby": ["Jab","Incision","Crush","Wave","Explosion"],#Укол Разрез Раcкол Волна Взрыв 
		"Wherewith": ["Glide","Parry","Block","Let","Teleport","Yoke"],#Скольжение Парирование Блок Барьер Блинк Захват
		"How": ["Distinct","Volley","Queue","Aim","Flow"],#Одиночный Самонаведение Луч Залп Очередь
		"What": ["Rune","Seal","Hex","Observance","Massif"]#Руна Печать Заклинание Ритуал Массив
		}
	list.ability_help.time = {
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
	list.ability_help.cargo = {
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
	
	list.ability_help.actions = ["Attack","Defense"]
	list.ability_help.basic_abilitys = {}
	
	for action in list.ability_help.actions:
		list.ability_help.basic_abilitys[action] = []
		var wherebys = []
		var wherewiths = []
		
		match action:
			"Attack":
				wherebys = ["Jab","Incision","Crush"]
			"Defense":
				wherewiths = ["Glide","Block"]
	
		for whereby in wherebys:
			var obj = {
				"Index": Global.list.primary_key.ability,
				"Name": "Basic "+whereby,
				"Action": action,
				"Whereby": whereby,
				"How": "Distinct",
				"What": "Hex"
			}
			var ability = Battleground.Ability.new(obj)
			array.abilitys.append(ability)
			list.ability_help.basic_abilitys[action].append(Global.list.primary_key.ability)
			Global.list.primary_key.ability += 1
	
		for wherewith in wherewiths:
			var obj = {
				"Index": Global.list.primary_key.ability,
				"Name": "Basic "+wherewith,
				"Action": action,
				"Wherewith": wherewith,
				"What": "Hex"
			}
			var ability = Battleground.Ability.new(obj)
			array.abilitys.append(ability)
			list.ability_help.basic_abilitys[action].append(Global.list.primary_key.ability)
			Global.list.primary_key.ability += 1

func init_array():
	array.abilitys = []
	array.modules = []
	array.danger_types = ["Weak","Middle","Strong"]
	array.module_types = ["Generator","Engine","Sensor","Disguise","AI","Gun","Protection"]
	array.souls = []
	array.alternatives = []
	array.items = []
	array.lots = []
	array.sequences = []
	array.verges = []
	array.recipes = []
	array.boundarys = []
	array.contestants = []
	array.arenas = []

func init_node():
	#usless
	node.root = get_node("/root")
	node.main = get_node("/root/main")
	node.maze = get_node("/root/main/maze")
	node.battleground = get_node("/root/main/battleground")

func init_list():
	init_stamina_expense()
	init_primary_key()
	init_ability_help()
	init_sdiw()
	
	list.booty_list = {}
	list.booty_list = {
		"herb breed 0": "extract",
		"herb breed 1": "extract",
		"herb breed 2": "extract"
	}
	list.temper_types = {}
	list.temper_types = {
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

func init_object():
	object.fibonacci = Loot.Fibonacci.new()
	object.rialto = Bourse.Rialto.new()

func init_flag():
	flag.ready = false

func _ready():
	init_node()
	init_array()
	init_list()
	init_object()
	init_flag()

func get_index_in_array(array_, index_):
	var child = null
	
	for child_ in array_:
		if child_.index == index_:
			#print(index_, "<find child>",child_.index)
			child = child_
	
	if child == null:
		var errors = []
		for obj in array_:
			errors.append(obj.index)
		print("error index ", index_, errors)
	return child

func triangle_check(verges, l):
	var flag = l > verges[0] + verges[1] + verges[2]
	
	if flag:
		flag = verges[0] > 0 && verges[1] > 0 && verges[2] > 0
		
		if flag:
			flag = flag && verges[0] + verges[1] > verges[2]
			flag = flag && verges[1] + verges[2] > verges[0]
			flag = flag && verges[2] + verges[0] > verges[1]
	
	return flag

func short_key_by_stat(stat_):
	for short_key in list.SDIW.short_keys:
		for long_key in list.SDIW.long_keys:
			if list.SDIW.list[short_key][long_key] == stat_:
				return short_key

func long_key_by_stat(stat_):
	for short_key in list.SDIW.short_keys:
		for long_key in list.SDIW.long_keys:
			if list.SDIW.list[short_key][long_key] == stat_:
				return long_key

func update_stat(owner_,stat_, value_):
	var index_ = Global.list.SDIW.data_indexs[stat_]
	var l_key = Global.long_key_by_stat(stat_)
	owner_.stats.long_keys[l_key] += value_
	var s_key = Global.short_key_by_stat(stat_)
	owner_.stats.short_keys[s_key] += value_
	owner_.stats.sqrts[index_] += value_
	owner_.stats.sum += value_

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
