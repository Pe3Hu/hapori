extends Node


var main
var rng = RandomNumberGenerator.new()
var stamina_expense = {}
var primary_key = {}

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

func _ready():
	main = get_node("/root/main")
	init_stamina_expense()
	init_primary_key()

class Soul:
	var index
	var vocations = []
	var alternative = []
	var priority = null
	var duty_cycle = []
	var temp = {}
	var parent
	var bag = {}
	var stamina = {}
	var reserve = {}
	var greed = {}
	var lot = {}
	var essence = 100
	var bidding = false
	var after_trade = []

	func init(obj):
		index = obj.index
		parent = obj.parent
		init_bag()
		init_greed()
		set_priority()

	func init_bag():
		bag.max_weight = 100
		bag.curret_weight = 0
		bag.max_items = 10
		bag.item_indexs = []

		stamina.total = 100
		stamina.current = stamina.total
		stamina.expense = 0
		stamina.overheat = 0

	func init_greed():
		Global.rng.randomize()
		var scatter = Global.rng.randf_range(0.5, 2)
		Global.rng.randomize()
		var minimum = Global.rng.randf_range(0, 2-scatter)
		Global.rng.randomize()
		var benchmark = Global.rng.randf_range(0, scatter)
		greed.min = minimum
		greed.max = minimum+scatter
		greed.benchmark = benchmark
		greed.augment = 0.1

	func set_priority():
		var options = []

		for alternative in Global.main.alternatives:
			for predispose in alternative.predisposes:
				var index_f = vocations.find(predispose.vocation)
				if index_f != -1:
					var flag = true

					if alternative.name == "auction selling":
						if bag.item_indexs.size() <= 0:
							flag = false

					if flag:						
						options.append(alternative.name)

		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, options.size()-1)
		priority = options[index_r]

		set_duty_cycle()

	func set_duty_cycle():
		duty_cycle = []
		temp.time_cost = 0

		match priority:
			"herbal harvest":
				duty_cycle.append("rest")
				duty_cycle.append("select prey")
				duty_cycle.append("select wetland")
				duty_cycle.append("wetland reserve")
				duty_cycle.append("wetland trip")
				duty_cycle.append("prey espial")
				duty_cycle.append("return trip")
			"auction selling":
				duty_cycle.append("rest")
				duty_cycle.append("select lot for auction selling")
				duty_cycle.append("registration for auction")
				duty_cycle.append("bidding")
			"auction buying":
				duty_cycle.append("rest")
				duty_cycle.append("select lot for auction buying")
				duty_cycle.append("registration for auction")
				duty_cycle.append("bidding")

		duty_cycle.append("move on")

	func what_should_i_do():
		if bidding == false:
			temp.task = duty_cycle.pop_front()

		match temp.task:
			"rest":
				rest()
			"select prey":
				temp.time_cost = 0.1
				find_best_prey()
			"select wetland":
				temp.time_cost = 0.1
				find_best_wetland()
			"wetland reserve":
				temp.time_cost = 0.1
				wetland_reserve()
			"wetland trip":
				temp.time_cost = 0.5
			"prey espial":
				prey_espial()
			"return trip":
				temp.time_cost = 0.5
			"discover vocation":
				discover_vocation()
			"select lot for auction buying":
				temp.time_cost = 0.1
				select_buying_lot()
			"select lot for auction selling":
				select_selling_lot()
				temp.time_cost = 0.1
			"registration for auction":
				registration_for_auction()
				temp.time_cost = 0.1
			"bidding":
				temp.time_cost = 0
				bidding = true
			"move on":
				set_priority()

		make_efforts()

	func make_efforts():
		var routines = ["select prey","select wetland","wetland reserve","select lot for auction buying","select lot for auction selling","registration for auction"]
		var trips = ["wetland trip","return trip"]
		var stasiss = ["bidding"]

		var index_f = routines.find(temp.task)
		if index_f != -1:
			stamina.expense = Global.stamina_expense.routine

		index_f = trips.find(temp.task)
		if index_f != -1:
			stamina.expense = Global.stamina_expense.trip

		index_f = stasiss.find(temp.task)
		if index_f != -1:
			stamina.expense = Global.stamina_expense.in_stasis
		
		match temp.task:
			"prey espial":
				stamina.expense = Global.stamina_expense.espial * temp.time_cost
		
		stamina.current -= stamina.expense
		essence += stamina.expense * 1
		
		if stamina.current < 0:
			stamina.overheat = -stamina.current
			stamina.current = 0

	func rest():
		var value = 0
		value += stamina.total - stamina.current
		value += pow(stamina.overheat, 2)
		stamina.current = stamina.total
		temp.time_cost = Global.stamina_expense.rest * value / stamina.total

	func find_best_prey():
		temp.best_prey = parent.rialto.sorted_prices[0]

	func find_best_wetland():
		var tiles = []
		
		for tile in parent.map.tiles:
			if tile.type == "meadow":
				if tile.landscape.breed == temp.best_prey:
					tiles.append(tile)
		
		var max_available = 0
		var options = []
		
		for tile in tiles:
			if tile.landscape.available.size() > max_available:
				max_available = tile.landscape.available.size()
				options = [ tile ]
			else:
				if tile.landscape.available.size() == max_available:
					options.append(tile)
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, options.size()-1)
		temp.best_wetland = options[index_r]

	func wetland_reserve():
		reserve.cols_count = 1
		var availables = temp.best_wetland.landscape.available
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, availables.size()-1)
		reserve.cols_begin = availables[index_r]
		availables.remove(index_r)

	func prey_espial():
		var seeds = temp.best_wetland.landscape.seeds
		var hitch_on_move = 0.01
		var hitch_on_overlook = 0.03
		var hitch_on_sprout = 0.05
		var move_time = 0
		var overlook_time = 0
		var sprout_time = 0
		
		for _c in reserve.cols_count:
			var _i = (reserve.cols_begin+_c)%seeds.size()
			
			for _j in seeds[_i].size():
				if seeds[_i][_j] != 0:
					sprout_time += pow(hitch_on_sprout,seeds[_i][_j])
					
					var item = Global.Item.new()
					item.features.where = temp.best_wetland
					item.features.what = "loot orb"
					item.features.grade = seeds[_i][_j]
					item.features.loss = {}
					item.features.loss.name = ""
					
					var input = {}
					input.complexity = item.features.grade + 2
					input.bonus = 0
					input.loss = ""
					input.amount = 0
					
					Global.main.fibonacci.roll(input)
					item.features.loss.name = input.loss
					item.features.loss.amount = input.amount
					
					if item.features.loss.name != "total":
						item.add_to_all_items()
						item.add_owner_bag(self)
						
					temp.best_wetland.pluck(_i,_j)
		
		move_time = reserve.cols_count * temp.best_wetland.landscape.n * hitch_on_move
		overlook_time = reserve.cols_count * temp.best_wetland.landscape.n * hitch_on_overlook
		temp.time_cost = move_time + overlook_time + sprout_time
		print("bag indexs",bag.item_indexs)

	func discover_vocation():
		temp.time_cost = 0

	func select_buying_lot():
		lot = Global.Lot.new()
		lot.owner = self
		lot.role = "buy"
		lot.what = "loot orb"
		lot.where = "herb breed 2"
		lot.components = []
		lot.market = null
		lot.item = null
		
	func select_selling_lot():
		lot = Global.Lot.new()
		lot.owner = self
		lot.role = "sell"
		lot.item = Global.main.items[bag.item_indexs[0]]
		lot.what = lot.item.features.what
		lot.where = lot.item.features.where.landscape.breed
		lot.components = []
		lot.market = null
		
		if true:#bag.cargo[lot.what][key].size() > quality_index:
#			var best_in_bag = bag.cargo[lot.what][key][quality_index]
#			lot.quality = key
#			lot.loss = best_in_bag.name
#			lot.integrity = best_in_bag.amount
#			lot.amount = 1
			lot.market = null
#			lot.give_index = quality_index
#			lot.give_key = key
		else:
			print('bag error')

	func registration_for_auction():
		Global.main.rialto.add_lot(lot)

	func die():
		var index_f = Global.main.souls.find(self)
		Global.main.souls.remove(index_f)
		
		if lot.keys().size() > 0:
			var lots = Global.main.rialto.lots
			index_f = lots[lot.role].find(lot)
			lots[lot.role].remove(index_f)

	func time_flow(delta):
		if duty_cycle.size() > 0:
			if temp.time_cost <= 0:
				what_should_i_do()
				if temp.task != "bidding":
					print(index," soul ", temp.task, "  ", essence)
			if !bidding:
				temp.time_cost -= delta
			
			if essence < 0:
				die()

class Tile: 
	var type
	var index
	var landscape = {}
	
	func set_(landscape):
		type = landscape.type
		index = landscape.index
		
		match type:
			"meadow":
				init_seeds(landscape.breed)
				burst_into_blossom()
	
	func init_seeds(_breed):
		landscape.grade = 1
		landscape.n = 10
		landscape.current_herb = 0 
		landscape.total_herb = landscape.n*3
		landscape.seeds = []
		landscape.available = []
		landscape.sourdough = false
		landscape.breed = _breed
		
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
	
	func sprout(_grade):
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
		
		landscape.seeds[_i][_j] = _grade
		landscape.current_herb += pow(_grade, 2)
	
	func pluck(_i,_j):
		landscape.current_herb -= pow(landscape.seeds[_i][_j], 2)
		landscape.seeds[_i][_j] = 0

class Rialto:
	var prices = {
		"loot orb": {
			"herb breed 0": 10,
			"herb breed 1": 20,
			"herb breed 2": 30
		}
	}
	var sorted_prices = ["herb breed 2","herb breed 1","herb breed 0"]
	var lots = {
		"sell":
			[],
		"buy":
			[]
	}
	var markets = []
	
	func add_lot(lot):
		lot.index = Global.primary_key.lot
		lot.price.deal = prices[lot.what][lot.where] * lot.owner.greed.benchmark
		lot.price.min = prices[lot.what][lot.where] * lot.owner.greed.min
		lot.price.max = prices[lot.what][lot.where] * lot.owner.greed.max
		var index = find_market(lot)
		lot.market = markets[index]
		markets[index].lots[lot.role].append(lot)
		markets[index].requirements_check()
		
		lots[lot.role].append(lot)
		Global.primary_key.lot += 1
	
	func find_market(lot):
		var exist_flag = false
		var market = null
		
		for _market in markets:
			if _market.subject == lot.what:
				exist_flag = true
				market = _market
		
		if !exist_flag:
			market = Global.Market.new()
			market.subject = lot.what
			market.price = prices[lot.what]
			markets.append(market)
		
		var index_f = markets.find(market)
		return index_f

	func time_flow(delta):
		for market in markets:
			if market.conduct:
				market.conduct()

class Fibonacci:
	var n = 10
	var numbers = [1,1]
	var sums = []
	var options = []
	#потери - все, осколки, сколы, трещины, потертости, никаких
	var loss = ["total","shards","chips","nicks","attritions","none"]
	var loss_indexs = []
	var criticals = 0

	func _init():
		for _i in n:
			var _l = numbers.size()
			var _f = numbers[_l-1] + numbers[_l-2]
			numbers.append(_f)
			
		for _l in numbers.size():
			var _s = 0
			
			if _l > 0:
				for _i in _l + 1:
					_s += numbers[_i]
				
				sums.append(_s)

	func roll(input):
		options = []
		loss_indexs = []
		criticals = 0
		
		for _i in input.complexity:
			for _j in numbers[_i]:
				options.append(_i)
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, options.size()-1)
		input.roll = options[index_r]
		input.index = index_r
		if input.roll == 0:
			input.shift = 0
		else:
			input.shift = index_r - sums[input.roll-2]
		input.max_shift = numbers[input.roll] - 1
		interpret_roll(input)

	func interpret_roll(input):
		var steps = input.complexity - loss_indexs.size()
		var iteration = ["total","not critical","none"]
		var _s = 0
		
		while _s < steps:
			var _i = _s % iteration.size()
			add_loss(iteration[_i])
			_s += 1
		
		input.loss = loss_indexs[input.roll]
		
		if criticals <= input.roll:
			if input.max_shift == 1:
				input.amount = 1
			else:
				var value = input.shift + 1
				var options = []
				var ceiled = ceil(sqrt(input.max_shift))
				
				for _i in ceiled:
					for _j in pow(_i,2):
						var amount = ceiled-_i
						options.append(amount)
				
				var index_r = Global.rng.randi_range(0, options.size()-1)
				input.amount = options[index_r]

	func add_loss(what):
		var value
		var pos
		
		match what:
			"total":
				value = 0
				criticals += 1
				pos = criticals - 1
			"none":
				value = loss.size()-1
				criticals += 1
				pos = 0
			"not critical":
				value = ((criticals + 1)/2)
				pos = criticals
				
		loss_indexs.insert(pos,loss[value])

class Alternative:
	var index
	var name
	var predisposes = []
	
	func set_index(_index): 
		index = _index
		var predispose
		
		match index:
			0:
				predispose = {}
				name = "herbal harvest"
				predispose.vocation = "getter"
				predispose.pressure = 10
				predisposes.append(predispose)
			1:
				name = "auction buying"
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 10
				predisposes.append(predispose)
			2:
				name = "auction selling"
				predispose = {}
				predispose.vocation = "getter"
				predispose.pressure = 10
				predisposes.append(predispose)
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 2
				predisposes.append(predispose)
			-1:
				name = "choose recipe"
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 20
				predisposes.append(predispose)

class Market: 
	var subject = null
	var price = null
	var lots = {
		"buy": [],
		"sell": []
	}
	var requirements = {
		"buy": 1,
		"sell": 1
	}
	var conduct = false
	
	func requirements_check():
		var flag = true
		
		for key in lots.keys():
			flag = flag && lots[key].size() > requirements[key]
		
		conduct = flag
	
	func conduct():
		print("!conduct!")
		var keys = ["sell","buy"]
		
		if lots["buy"].size() < lots["sell"].size():
			keys = ["buy","sell"]
		
		var _i = lots[keys[0]].size()-1
		var options = {
			"sell": [],
			"buy": []
		}
		
		for key in lots.keys():
			options[key].append_array(lots[key])
		
		while _i >= 0:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, options[keys[1]].size()-1) 
			var deal = {}
			deal[keys[0]] = options[keys[0]][_i]
			deal[keys[1]] = options[keys[1]][index_r]
			 
			if deal_check(deal):
				deal["buy"].owner.essence -= deal["sell"].price.deal
				deal["sell"].item.add_owner_bag(deal["buy"].owner)
				deal["buy"].owner.bidding = false
				deal["sell"].owner.bidding = false
				print("!after deal! ",deal["sell"].owner.index,deal["sell"].owner.bag.item_indexs,deal["buy"].owner.index,deal["buy"].owner.bag.item_indexs)
			options[keys[0]].remove(_i)
			options[keys[1]].remove(index_r)
			_i -= 1
			
		lots["sell"] = options["sell"]
		lots["buy"] = options["buy"]
		requirements_check()
	
	func deal_check(deal):
		var current = deal["sell"].price.deal
		var flag = current < deal["buy"].price.max
		 
		print("!deal check!", deal["sell"].price, " ", deal["buy"].price)
		return flag

class Item:
	var index
	var source
	var owner
	var features = {}
	
	func add_to_all_items():
		index = Global.primary_key.item
		Global.primary_key.item += 1
		Global.main.items.append(self)
	
	func add_owner_bag(new_owner):
		if owner != null:
			var index_f = owner.bag.item_indexs.find(index)
			
			if index_f != -1:
				owner.bag.item_indexs.remove(index_f)
			
		owner = new_owner
		owner.bag.item_indexs.append(index)
	
	func destroy():
		var index_f = Global.main.items.find(self)
		
		if index_f != -1:
			Global.main.items.remove(index_f)
		
		if owner != null:
			index_f = owner.bag.item_indexs.find(index)
			
			if index_f != -1:
				owner.bag.item_indexs.remove(index_f)

class Lot:
	var index
	var role
	var what
	var where
	var components
	var owner
	var item
	var market
	var price = {}
