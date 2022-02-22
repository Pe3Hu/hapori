extends Node


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
	var lots = []
	var essence = 2000
	var bidding = false
	var outlay = {}
	var extract = {}
	var necessary = []
	var calculations = {}
	var scroll = {}
	var product = {}
	var recipes = []
	var unfinished = []
	var stop = false
	var bingo = false
	var finish = null

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
		extract["alpha"] = 10
		extract["beta"] = 10
		extract["gamma"] = 10
		calculations.failed = []
		calculations.current = null
		calculations.blunder = []
 
	func set_priority():
		if !stop:
			var options = []
			
			if necessary.size() > 0:
				lay_waste_bag()
				
			if necessary.size() > 0:
				options.append("buy necessary")
			else:
				if finish == null:
					for alternative in Global.array.alternatives:
						for predispose in alternative.predisposes:
							if vocations.has(predispose.vocation):
								var flag = true
							
								if alternative.name == "sell booty":
									if bag.item_indexs.size() <= 0:
										flag = false
								
								if alternative.name == "start making product":
									if recipes.size() == 0:
										flag = false
								
								if flag:
									for pressure in predispose.pressure:
										options.append(alternative.name)
				else:
					options.append(finish)

			#print(options)
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
				duty_cycle.append("registration for auction")
				duty_cycle.append("bidding")
			"start inventing recipe":
				duty_cycle.append("make calculation")
				duty_cycle.append("make necessary list")
				duty_cycle.append("receive necessary")
			"end inventing recipe":
				duty_cycle.append("check calculation")
				duty_cycle.append("clear finish")
			"start making product":
				duty_cycle.append("select recipe")
				duty_cycle.append("make necessary list")
				duty_cycle.append("receive necessary")
			"end making product":
				duty_cycle.append("follow recipe")
				duty_cycle.append("clear finish")
				
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
			"select lot for auction selling":
				select_selling_lot()
			"registration for auction":
				registration_for_auction()
			"make calculation":
				make_calculation()
			"make necessary list":
				make_necessary_list()
			"receive necessary":
				receive_necessary()
			"check calculation":
				check_calculation()
			"select recipe":
				select_recipe()
			"follow recipe":
				follow_recipe()
			"move on":
				set_priority()
			"bidding":
				temp.time_cost = 0
				bidding = true
			"clear finish":
				temp.time_cost = 0
				finish = null
		
		make_efforts()

	func make_efforts():
		var routines = []
		routines.append_array(["select prey","select wetland","wetland reserve"])
		routines.append_array(["select lot for auction selling","registration for auction", "make calculation"])
		routines.append_array(["make necessary list","receive necessary","check calculation"])
		routines.append_array(["select recipe","follow recipe"])
		var trips = ["wetland trip","return trip"]
		var stasiss = ["bidding","clear finish"]

		if routines.has(temp.task):
			stamina.expense = Global.list.stamina_expense.routine

		if trips.has(temp.task):
			stamina.expense = Global.list.stamina_expense.trip

		if stasiss.has(temp.task):
			stamina.expense = Global.list.stamina_expense.in_stasis
		
		match temp.task:
			"prey espial":
				stamina.expense = Global.list.stamina_expense.espial * temp.time_cost
		
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
		temp.time_cost = Global.list.stamina_expense.rest * value / stamina.total
		if outlay.flag:
			outlay.previous = outlay.current
			outlay.current = 0
			outlay.flag = false

	func find_best_prey():
		temp.time_cost = 0.1
		
		outlay.flag = true
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.object.rialto.sorted_prices.size()-1)
		temp.best_prey = Global.object.rialto.sorted_prices[index_r]

	func find_best_wetland():
		var tiles = []
		
		for tile in Global.object.map.tiles:
			if tile.type == "meadow":
				if tile.landscape.breed == temp.best_prey:
					tiles.append(tile)
		
		var max_available = 1
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
					
					var item = Loot.Item.new()
					item.features.where = temp.best_wetland.landscape.breed
					item.features.what = "loot orb"
					item.features.grade = seeds[_i][_j]
					item.features.loss = {}
					item.features.loss.name = ""
					
					var input = {}
					input.complexity = item.features.grade + 2
					input.bonus = 0
					input.loss = ""
					input.amount = 0
					
					Global.object.fibonacci.roll(input)
					item.features.loss.name = input.loss
					item.features.loss.amount = input.amount
					
					if item.features.loss.name != "total":
						item.add_to_all_items()
						item.add_owner_bag(self)
						
					temp.best_wetland.pluck(_i,_j)
		
		move_time = reserve.cols_count * temp.best_wetland.landscape.n * hitch_on_move
		overlook_time = reserve.cols_count * temp.best_wetland.landscape.n * hitch_on_overlook
		temp.time_cost = move_time + overlook_time + sprout_time

	func discover_vocation():
		temp.time_cost = 0

	func select_selling_lot():
		temp.time_cost = 0.1
		
		postpone()
		
		for index_ in bag.item_indexs:
			var lot = Bourse.Lot.new()
			lot.owner = self
			lot.role = "sell"
			lot.item = Global.get_index_in_array(Global.array.items,index_)
			lot.what = lot.item.features.what
			lot.where = lot.item.features.where
			lot.components = []
			lot.market = null
			lot.outlay = int(outlay.previous)
			lots.append(lot)

	func postpone():
		return

	func registration_for_auction():
		temp.time_cost = 0.1
		
		for lot in lots:
			Global.object.rialto.add_lot(lot)

	func make_calculation():
		temp.time_cost = 0.1
		
		if calculations.failed.size() == 0:
			generate_calculation()
		else:
			reinvent()

	func generate_calculation():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.array.sequences.size()-1)
		var sequence = Global.array.sequences[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, Global.array.verges.size()-1)
		var verges = Global.array.verges[index_r]
		
		calculations.current = Member.Calculation.new()
		calculations.current.set_extract(sequence, verges)

	func reinvent():
		calculations.current = Member.Calculation.new()
		calculations.current.categorize_all(calculations.failed)

	func make_necessary_list():
		temp.time_cost = 0.1
		match priority:
			"start inventing recipe":
				scroll = calculations.current.extract
			"start making product":
				scroll = product.extract
		print("extract necessary list ",scroll)
		 
		for _i in scroll.keys().size():
			var key = scroll.keys()[_i]
			var shortage = scroll[key] - extract[key]
		
			if shortage > 0:
				var where
				
				match _i:
					0:
						where = "herb breed 0"
					1:
						where = "herb breed 1"
					2:
						where = "herb breed 2"
				
				var need = {}
				need.min = scroll[key]
				need.key = key
				need.where = where
				necessary.append(need)

	func lay_waste_bag():
		var i = Global.array.items
		var b = bag.item_indexs
		
		for index_ in bag.item_indexs:
			var item = Global.get_index_in_array(Global.array.items,index_)
			print(index, " try open")
			item.open()
			
		#print(necessary)
		for _i in range(necessary.size()-1,-1,-1):
			if extract[necessary[_i].key] >= necessary[_i].min: 
				necessary.remove(_i)
		#print(necessary)

	func receive_necessary():
		temp.time_cost = 0.1
		
		if necessary.size() > 0:
			for necessary_ in necessary:
				var lot = Bourse.Lot.new()
				lot.owner = self
				lot.role = "buy"
				lot.what = "loot orb"
				lot.where = necessary_.where
				lot.components = []
				lot.market = null
				lot.item = null
				
				lots.append(lot)
				
		finish = priority 
		finish.erase(0,5)
		finish = "end"+finish 
		#print(finish,necessary)

	func check_calculation():
		temp.time_cost = 0.1
		#print(necessary,calculations.current.extract)
		for key in calculations.current.extract.keys():
			extract[key] -= calculations.current.extract[key]
		
		calculations.current.set_hints(calculations.failed)
		
		if calculations.current != null:
			if !calculations.current.fail:
				if !calculations.current.hints.success:
					calculations.failed.append(calculations.current)
				else:
					bingo = true
					print("!bingo!")
					recipes.append(calculations.current.recipe)
					calculations.failed = []
					calculations.current = null
				calculations.blunder.append(calculations.current)
		else:
			stop = true
	
	func select_recipe():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, recipes.size()-1)
		product = {}
		product.recipe = recipes[index_r]
		product.extract = product.recipe.extract
		
	func follow_recipe():
		for key in product.extract .keys():
			extract[key] -= product.extract[key]

	func die():
		var index_f = Global.array.souls.find(self)
		Global.array.souls.remove(index_f)
		print(index, "-----",   Global.array.souls.size())
		if lots.size() > 0:
			var lots_ = Global.object.rialto.lots
			
			for lot in lots:
				index_f = lots_[lot.role].find(lot)
				lots_[lot.role].remove(index_f)

	func time_flow(delta):
		if duty_cycle.size() > 0:
			if temp.time_cost <= 0:
				what_should_i_do()
				
				if !stop:
#					if temp.task != "bidding" && index > 9:
#						print(index," soul ", temp.task, "  ", essence)
					do_it()
				
			if !bidding:
				temp.time_cost -= delta*25
			
			if essence < 0:
				die()

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
				name = "sell booty"
				predispose = {}
				predispose.vocation = "getter"
				predispose.pressure = 10
				predisposes.append(predispose)
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 1
				predisposes.append(predispose)
			2:
				name = "start inventing recipe"
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 1
				predisposes.append(predispose)
			3:
				name = "start making product"
				predispose = {}
				predispose.vocation = "artificer"
				predispose.pressure = 10
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
			var index_f = sequence.find(_j)
			
			match _j:
				0: 
					extract["alpha"] = verges_[index_f]
				1: 
					extract["beta"] = verges_[index_f]
				2: 
					extract["gamma"] = verges_[index_f]

	func set_hints(fails):
		if fails.size() == 0:
			best_hints()
		else:
			recipe = fails[0].recipe
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
			
			if reruns_a.keys().has(_recipe.verges[_i]):
				reruns_a[_recipe.verges[_i]] += 1
			else:
				reruns_a[_recipe.verges[_i]] = 1
			
			if verges.has(_recipe.verges[_i]):
				coincided.verges += 1
				
				if flag:
					coincided.sequence -= 1
					coincided.verges -= 1
					coincided.extract += 1
		
		var reruns_b = {}
		
		for _i in verges.size():
			if reruns_b.keys().has(verges[_i]):
				reruns_b[verges[_i]] += 1
			else:
				reruns_b[verges[_i]] = 1
	
		for key in reruns_b.keys():
			if reruns_a.keys().has(key):
				var shift = reruns_a[key] - reruns_b[key]

				if shift < 0:
					coincided.sequence += shift
					coincided.extract -= shift
				else:
					coincided.verges -= shift
		
		coincided.rate += coincided.sequence + coincided.verges + coincided.extract * 4
		coincided.success = coincided.extract == _recipe.sequence.size()
		return coincided

	func best_hints():
		var coincideds = []
		
		for _recipe in Global.array.recipes:
			if _recipe.sum == sum:
				var coincided = set_coincided(_recipe)
				coincideds.append(coincided)
		
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
			recipe = Global.array.recipes[hints.recipe]

	func categorize_all(fails):
		var sequence_options = []
		
		for sequence_ in Global.array.sequences:
			sequence_options.append(sequence_)
		
		var _i = sequence_options.size() - 1
		
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
		
		var bans = []
		
		for fail_ in fails:
			if fail_.hints.verges + fail_.hints.extract == 0:
				for verge in fail_.verges:
					if !bans.has(verge):
						bans.append(verge)
		
		var verges_options = []
		var sum_f = fails[0].sum
		
		for verges_ in Global.array.verges:
			var sum_ = 0
			
			for verge in verges_:
				sum_ += verge
			
			if sum_f == sum_:
				verges_options.append(verges_) 
		
		_i = verges_options.size() - 1
		
		while _i >= 0:
			var option = verges_options[_i]
			var flag = false
			
			for verge in option:
				flag = flag || bans.has(verge)
			
			if flag:
				verges_options.remove(_i)
			else:
				flag = true 
				
				for fail_ in fails:
					var count = 0
					
					for _j in option.size():
						if option.has(fail_.verges[_j]):
							count += 1
					
					flag = count == fail_.hints.verges + fail_.hints.extract
				
				if !flag:
					verges_options.remove(_i)
			_i -= 1
		
		var combination_options = []
		
		for sequence_option in sequence_options:
			for verges_option in verges_options:
				var combination = {}
				combination.sequence = sequence_option
				combination.verges = verges_option
				
				combination_options.append(combination)
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, combination_options.size()-1)
		var combination = combination_options[index_r]
		set_extract(combination.sequence, combination.verges)
		recipe = fails[0].recipe

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
		
		for _i in verges.size():
			flag = flag && verges[_i] == recipe.verges[_i]
		return flag
