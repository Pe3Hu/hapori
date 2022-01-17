extends Node


var main
var maze
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
	primary_key.soul = 0
	primary_key.recipe = 0
	primary_key.road = 0
	primary_key.highway = 0
	primary_key.crossroad = 0

func _ready():
	main = get_node("/root/main")
	maze = get_node("/root/main/mazeIsometric")
	init_stamina_expense()
	init_primary_key()

func triangle_check(verges, l):
	var flag = l > verges[0] + verges[1] + verges[2]
	
	if flag:
		flag = verges[0] > 0 && verges[1] > 0 && verges[2] > 0
		
		if flag:
			flag = flag && verges[0] + verges[1] > verges[2]
			flag = flag && verges[1] + verges[2] > verges[0]
			flag = flag && verges[2] + verges[0] > verges[1]
	
	return flag

class Soul:
	var index
	var vocations = []
	var alternatives = []
	var priority = null
	var duty_cycle = []
	var temp = {}
	var parent
	var bag = {}
	var stamina = {}
	var reserve = {}
	var greed = {}
	var lot = {}
	var essence = 1000
	var bidding = false
	var outlay = {}
	var extract = {}
	var necessary = []
	var invent = false
	var calculations = {}
	var recipes = []
	var stop = false
	var bingo = false

	func init(obj):
		index = obj.index
		parent = obj.parent
		init_bag()
		init_greed()
		init_extracts()
		set_priority()
		outlay.flag = false
		outlay.current = 0
		outlay.previous = 0

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
		var scatter = Global.rng.randi_range(50, 200)
		Global.rng.randomize()
		var minimum = Global.rng.randi_range(0, 200-scatter)
		Global.rng.randomize()
		var benchmark = Global.rng.randi_range(0, scatter)
		greed.min = -1+minimum*0.01
		greed.max = greed.min+scatter*0.01
		greed.benchmark = greed.min+benchmark*0.01
		greed.augment = 0.05
		greed.markup = {
			"sell": 0.15,
			"buy": -0.15
		}

	func init_extracts():
		extract.alpha = 1000
		extract.beta = 1000
		extract.gamma = 1000
		calculations.failed = []
		calculations.current = null
		calculations.blunder = []
 
	func set_priority():
		if !stop:
			var options = []
			
			for alternative in Global.main.alternatives:
				for predispose in alternative.predisposes:
					var index_f = vocations.find(predispose.vocation)
					
					if index_f != -1:
						var flag = true
						
						if alternative.name == "sell booty":
							if bag.item_indexs.size() <= 0:
								flag = false
						
						if alternative.name == "buy necessary":
							if necessary.size() <= 0:
								flag = false
						
						if alternative.name == "invent recipe":
							if !bingo && invent:
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
				duty_cycle.append("select prey")
				duty_cycle.append("select wetland")
				duty_cycle.append("wetland reserve")
				duty_cycle.append("wetland trip")
				duty_cycle.append("prey espial")
				duty_cycle.append("return trip")
			"sell booty":
				duty_cycle.append("select lot for auction selling")
				duty_cycle.append("registration for auction")
				duty_cycle.append("bidding")
			"buy necessary":
				duty_cycle.append("select lot for auction buying")
				duty_cycle.append("registration for auction")
				duty_cycle.append("bidding")
			"invent recipe":
				duty_cycle.append("make calculation")
				duty_cycle.append("make necessary list")
				duty_cycle.append("receive necessary")
				duty_cycle.append("check calculation")
				
		duty_cycle.append("rest")
		duty_cycle.append("move on")

	func what_should_i_do():
		if stop:
			duty_cycle = []
			temp.task = ""
			return
			
		if bidding == false:
			temp.task = duty_cycle.pop_front()

	func do_it():
		match temp.task:
			"rest":
				rest()
			"select prey":
				find_best_prey()
			"select wetland":
				find_best_wetland()
			"wetland reserve":
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
				select_buying_lot()
			"select lot for auction selling":
				select_selling_lot()
			"registration for auction":
				registration_for_auction()
			"bidding":
				temp.time_cost = 0
				bidding = true
			"make calculation":
				make_calculation()
			"make necessary list":
				make_necessary_list()
			"receive necessary":
				receive_necessary()
			"check calculation":
				check_calculation()
			"move on":
				set_priority()
		
		make_efforts()

	func make_efforts():
		var routines = []
		routines.append_array(["select prey","select wetland","wetland reserve","select lot for auction buying"])
		routines.append_array(["select lot for auction selling","registration for auction", "make calculation"])
		routines.append_array(["make necessary list","receive necessary","check calculation"])
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
		if outlay.flag:
			outlay.current -= stamina.expense * 1
		
		if stamina.current < 0:
			stamina.overheat = -stamina.current
			stamina.current = 0

	func rest():
		var value = 0
		value += stamina.total - stamina.current
		value += pow(stamina.overheat, 2)
		stamina.current = stamina.total
		temp.time_cost = Global.stamina_expense.rest * value / stamina.total
		if outlay.flag:
			outlay.previous = outlay.current
			outlay.current = 0
			outlay.flag = false

	func find_best_prey():
		outlay.flag = true
		temp.time_cost = 0.1
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
		temp.time_cost = 0.1
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
		temp.time_cost = 0.1
		lot = Global.Lot.new()
		lot.owner = self
		lot.role = "buy"
		lot.what = "loot orb"
		lot.where = "herb breed 2"
		lot.components = []
		lot.market = null
		lot.item = null

	func select_selling_lot():
		temp.time_cost = 0.1
		lot = Global.Lot.new()
		lot.owner = self
		lot.role = "sell"
		lot.item = Global.main.items[bag.item_indexs[0]]
		lot.what = lot.item.features.what
		lot.where = lot.item.features.where.landscape.breed
		lot.components = []
		lot.market = null
		lot.outlay = int(outlay.previous)

	func registration_for_auction():
		temp.time_cost = 0.1
		Global.main.rialto.add_lot(lot)

	func make_calculation():
		temp.time_cost = 0.1
		
		print("calculation № ",calculations.failed.size())
		
		if !bingo:
			if calculations.failed.size() == 0:
				generate_calculation()
			else:
				reinvent()
				print("previous fail:",calculations.failed[calculations.failed.size()-1].verges)
			
			invent = true
		else:
			stop = true

	func generate_calculation():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.main.sequences.size()-1)
		var sequence = Global.main.sequences[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, Global.main.verges.size()-1)
		var verges = Global.main.verges[index_r]
		
		calculations.current = Global.Calculation.new()
		calculations.current.set_extract(sequence, verges)

	func reinvent():
		calculations.current = Global.Calculation.new()
		calculations.current.categorize_all(calculations.failed)
		if calculations.current.check_reinvent():
			print("-pre bingo-")
		#print(index, " reinvent")

	func make_necessary_list():
		temp.time_cost = 0.1
		print("extract necessary list ",calculations.current.extract)
		 
		for _i in calculations.current.extract.keys().size():
			var key = calculations.current.extract.keys()[_i]
			var shortage = calculations.current.extract[key] - extract[key]
			
			if shortage > 0:
				match _i:
					0:
						necessary.append("herb breed 0")
					1:
						necessary.append("herb breed 1")
					2:
						necessary.append("herb breed 2")

	func receive_necessary():
		temp.time_cost = 0.1

	func check_calculation():
		temp.time_cost = 0.1
		
		for key in calculations.current.extract.keys():
			extract[key] -= calculations.current.extract[key]
		
		calculations.current.set_hints(calculations.failed)
		
		if calculations.current != null:
			if !calculations.current.fail:
				if !calculations.current.hints.success:
					calculations.failed.append(calculations.current)
				else:
					print("+bingo+")
					bingo = true
				calculations.blunder.append(calculations.current)
		else:
			stop = true
			
		invent = false

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
				
				do_it()
				
			if !bidding:
				temp.time_cost -= delta
			
			if essence < 0:
				die()

class Tile: 
	var type
	var index
	var landscape = {}

	func set_(_landscape):
		type = _landscape.type
		index = _landscape.index
		
		match type:
			"meadow":
				init_seeds(_landscape.breed)
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
			"herb breed 0": 50,
			"herb breed 1": 75,
			"herb breed 2": 100
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
		lot.price.deal = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.benchmark)
		lot.price.min = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.min)
		lot.price.max = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.max)
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
			#print("requirements_check ", key, flag, lots[key].size())
		
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
				deal["buy"].owner.essence -= deal["sell"].outlay
				deal["sell"].owner.essence += deal["sell"].price.deal
				deal["sell"].owner.essence += deal["sell"].outlay
				deal["sell"].item.add_owner_bag(deal["buy"].owner)
				deal["buy"].owner.bidding = false
				deal["sell"].owner.bidding = false
				print("!!!!!!after deal! ",deal["sell"].owner.index,deal["sell"].owner.bag.item_indexs,deal["buy"].owner.index,deal["buy"].owner.bag.item_indexs)
				print(deal["sell"].price.deal, " outlay ", deal["sell"].outlay)
				print(deal["sell"].owner.greed,deal["buy"].owner.greed)
				
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
	var outlay

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
				#var value = input.shift + 1
				var _options = []
				var ceiled = ceil(sqrt(input.max_shift))
				
				for _i in ceiled:
					for _j in pow(_i,2):
						var amount = ceiled-_i
						_options.append(amount)
				
				var index_r = Global.rng.randi_range(0, _options.size()-1)
				input.amount = _options[index_r]

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
				name = "buy necessary"
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 1
				predisposes.append(predispose)
			2:
				name = "sell booty"
				predispose = {}
				predispose.vocation = "getter"
				predispose.pressure = 10
				predisposes.append(predispose)
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 2
				predisposes.append(predispose)
			3:
				name = "invent recipe"
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

class Calculation:
	var extract = {}
	var sequence = []
	var verges = []
	var recipe = null
	var sum = 0
	var hints = {}
	var fail = false
	var guess = []
	var facts = []
	
	func set_extract(sequence_, verges_):
		sequence.append_array(sequence_) 
		verges.append_array(verges_) 
		
		for verge in verges:
			sum += verge
		
		for _j in sequence:
			var index = sequence.find(_j)
			
			match _j:
				0: 
					extract.alpha = verges_[index]
				1: 
					extract.beta = verges_[index]
				2: 
					extract.gamma = verges_[index]

	func set_hints(fails):
		if fails.size() == 0:
			best_hints()
		else:
			recipe = Global.main.recipes[fails[0].recipe]
			hints = set_coincided(recipe)

	func set_coincided(_recipe):
		var coincided = {}
		coincided.sequence = 0
		coincided.verges = 0
		coincided.extract = 0
		coincided.recipe = _recipe.index
		coincided.rate = 1
		
		var reruns_a = {}
		
		for _i in _recipe.sequence.size():
			var flag = false
			
			if _recipe.sequence[_i] == sequence[_i]:
				coincided.sequence += 1
				flag = true
			
			if reruns_a.keys().find(_recipe.verges[_i]) == -1:
				reruns_a[_recipe.verges[_i]] = 1
			else:
				reruns_a[_recipe.verges[_i]] += 1
			
			var index_f = verges.find(_recipe.verges[_i])
			
			if index_f != -1:
				coincided.verges += 1
				
				if flag:
					coincided.sequence -= 1
					coincided.verges -= 1
					coincided.extract += 1
		
		var reruns_b = {}
		
		for _i in verges.size():
			if reruns_b.keys().find(verges[_i]) == -1:
				reruns_b[verges[_i]] = 1
			else:
				reruns_b[verges[_i]] += 1
		
		print(">",reruns_a, reruns_b)
		print("=",sequence, verges)
		print("=",_recipe.sequence, _recipe.verges)
		print("@",coincided)
	
		for key in reruns_b.keys():
			var index_f = reruns_a.keys().find(key)
			
			if index_f != -1:
				var shift = reruns_a[key] - reruns_b[key]

				if shift > 0:
					coincided.sequence += shift
					coincided.extract -= shift
		
		print("^",coincided)
		
		coincided.rate += coincided.sequence + coincided.verges + coincided.extract * 4
		coincided.success = coincided.extract == _recipe.sequence.size()
		return coincided

	func best_hints():
		var coincideds = []
		
		for _recipe in Global.main.recipes:
			if _recipe.sum == sum:
				var coincided = set_coincided(_recipe)
				coincideds.append(coincided)
				print("recipe index: ",_recipe.index)
		
		if coincideds.size() == 0:
			fail = true
		else:
			var options = []
			
			for _i in coincideds.size():
				for _j in coincideds[_i].rate:
					options.append(_i)
			
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, options.size()-1)
			hints = coincideds[options[index_r]]
			recipe = hints.recipe
			print("#",hints)

	func categorize_extract(fails):
		var indexs = [0,1,2]
		var fact_counter = 0
		
		for fact in facts:
			if fact.sequence:
				fact_counter += 1
		
		if fact_counter == 3:
			sequence = [-1,-1,-1]
			
			for fact in facts:
				if fact.sequence:
					sequence[fact.fail.sequence[fact.index]] = fact.index
			
			return
		else:
			var options = []
			
			for _fail in fails:
				if _fail.hints.sequences == 0:
					for sequences_ in Global.sequences:
						return

	func categorize_sequence(fails):
		if guess.size() > 0:
			for guess_ in guess:
				if guess_.sequence:
					swap_sequence(guess_)
					return 
		else:
			if fails.size() > 0:
				return

	func categorize_verges(fails):
		pass

	func categorize_all(fails):
		var sequence_options = []
		var verges_options = []
		var sum_f = fails[0].sum
		
		for sequence_ in Global.main.sequences:
			sequence_options.append(sequence_)
		
		for verges_ in Global.main.verges:
			var sum_ = 0
			
			for verge in verges_:
				sum_ += verge
			
			if sum_f == sum_:
				verges_options.append(verges_) 
		
		var _i = sequence_options.size() - 1
		print("verges: ",verges_options)
		
		while _i >= 0:
			var option = sequence_options[_i]
			var flag = true
			
			for fail_ in fails:
				var count = 0
				
				for _j in option.size():
					if option[_j] == fail_.sequence[_j]:
						count += 1
				
				flag = count == fail_.hints.sequence + fail_.hints.extract
			
			if !flag:
				sequence_options.remove(_i)
			
			_i -= 1
		
		_i = verges_options.size() - 1
		
		while _i >= 0:
			var option = verges_options[_i]
			var flag = true
			
			for fail_ in fails:
				var count = 0
				
				for _j in option.size():
					var index_f = option.find(fail_.verges[_j])
					
					if index_f != -1:
						count += 1
				
				flag = count == fail_.hints.verges + fail_.hints.extract
			
			if !flag:
				verges_options.remove(_i)
			
			_i -= 1
			
		print("final recipe: ",Global.main.recipes[fails[0].recipe].sequence, Global.main.recipes[fails[0].recipe].verges)
		print("last fail: ",fails[fails.size()-1].sequence,fails[fails.size()-1].verges)
		print("options: ",sequence_options,verges_options)
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, sequence_options.size()-1)
		var sequence_ = sequence_options[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, verges_options.size()-1)
		var verges_ = verges_options[index_r]
		set_extract(sequence_, verges_)
		recipe = Global.main.recipes[fails[0].recipe]

	func swap_sequence(guess_):
		var sequence_flag = [true,true,true]
		var old_indexs = []
		var swaped_indexs = []
		sequence_flag[guess_.index] = false
		
		for _i in sequence_flag.size():
			if sequence_flag[_i]:
				old_indexs.push(_i)
		
		for _i in sequence_flag.size():
			if sequence_flag[_i]:
				swaped_indexs.push(_i)
			else:
				var obj = {}
				obj.fail = guess_.fail
				obj.index = old_indexs.pop_back()
				obj.sequence = true
				obj.verges = false
				guess.append(obj)

	func check_extract(fails, fail_, index_r):
		var flag = true
		
		for f in fails:
			if fail_ != fail:
				if fail_.sequence[index_r] == fail.sequence[index_r] && fail_.verges[index_r] == f.verges[index_r]:
					if f.hints.extract == 0:
						flag = false
		return flag

	func check_guess(fail_):
		var flag = true
		
		for guess_ in guess:
			if guess_.sequence:
				flag = fail_.sequence[guess_.index] != guess_.fail_.sequence[guess_.index]
			if guess_.verges:
				flag = fail_.verges[guess_.index] != guess_.fail.verges[guess_.index]
		return flag

	func check_reinvent():
		var flag = true
		
		for _i in sequence.size():
			flag = flag && sequence[_i] == recipe.sequence[_i]
			#print(sequence[_i], recipe.sequence[_i])
		
		for _i in verges.size():
			flag = flag && verges[_i] == recipe.verges[_i]
			#print(verges[_i], recipe.verges[_i])
		return flag

class Recipe:
	var index
	var extract = {}
	var sequence = []
	var verges = []
	var sum = 0
	
	func set_extract(sequence_, verges_):
		sequence.append_array(sequence_) 
		verges.append_array(verges_) 
		
		for verge in verges:
			sum += verge
		
		for _j in sequence:
			var index_f = sequence.find(_j)
			
			match _j:
				0: 
					extract.alpha = verges_[index_f]
				1: 
					extract.beta = verges_[index_f]
				2: 
					extract.gamma = verges_[index_f]

class Cell:
	var index
	var grid
	var tile
	var neighbors = []
	var roads = []
	var highways = []
	var crossroad = -1

class Highway:
	var index
	var roads = []
	var crossroads = []
	var cells = []
	var branchs = []
