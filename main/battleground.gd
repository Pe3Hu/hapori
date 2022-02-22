extends Node2D


class Point:
	var x
	var y
	
	func _init(x_,y_):
		x = x_
		y = y_

class Rectangle:
	var index
	var x
	var y
	var w
	var h
	var points = []

	func _init(x_,y_,w_,h_):
		x = x_
		y = y_
		w = w_
		h = h_

	func contains(point):
		return  point.x >= x-w && point.x < x+w && point.y >= y-h && point.y < y+h


	func intersects(range_):
		return !(
			range_.x-range_.w>x+w ||
			range_.x+range_.w<x-w ||
			range_.y-range_.h>y+h ||
			range_.y+range_.h<y-h
		)

class QuadTree:
	var boundary
	var capacity
	var points = []
	var divided = false
	var childs = {}
	
	func _init(boundary_,capacity_):
		boundary = boundary_
		capacity = capacity_

	func subdivide():
		var x = boundary.x
		var y = boundary.y
		var w = boundary.w
		var h = boundary.h
		
		var ne = Battleground.Rectangle.new(x+w/2_,y-h/2_,w/2_,h/2)
		childs.northeast = Battleground.QuadTree.new(ne,capacity)
		var nw = Battleground.Rectangle.new(x-w/2_,y-h/2_,w/2_,h/2)
		childs.northwest = Battleground.QuadTree.new(nw,capacity)
		var se = Battleground.Rectangle.new(x+w/2_,y+h/2_,w/2_,h/2)
		childs.southeast = Battleground.QuadTree.new(se,capacity)
		var sw = Battleground.Rectangle.new(x-w/2_,y+h/2_,w/2_,h/2)
		childs.southwest = Battleground.QuadTree.new(sw,capacity)
		divided = true

	func insert(point):
		if !boundary.contains(point):
			return  false
		if points.size() < capacity:
			points.append(point)
			return true
		else:
			if !divided:
				subdivide()
		if childs.northeast.insert(point):
			return true
		elif childs.northwest.insert(point):
			return true
		elif childs.southeast.insert(point):
			return true
		elif childs.southwest.insert(point):
			return true

	func query(range_,found_):
		var found = found_
		
		if !found_:
			found = []

		if !boundary.intersects(range_):
			return 
		else:
			for point in points:
				if range_.contains(point):
					found.append(point)
		
		if divided:
			childs.northwest.query(range_,found)
			childs.northeast.query(range_,found)
			childs.southwest.query(range_,found)
			childs.southeast.query(range_,found)
		return found
		
	func show(rects):
		var rect = Rect2(Vector2(boundary.x,boundary.y),Vector2(boundary.w,boundary.h))
		rects.append(rect)
		
		if divided:
			childs.northeast.show(rects)
			childs.northwest.show(rects)
			childs.southeast.show(rects)
			childs.southwest.show(rects)

class Arena:
	var index
	var boundary
	var contestants = []
	var dangers = []
	var hassles = []
	var dropouts = []
	var rules = {}
	var altercations = {}
	var timeline = {}
	var time = 0
	var size = 0
	var winner_modules = []
	var teams = {}
	
	func fight():
		size = contestants.size()
		rules.initiative = "max"
		
		prepare_fight()
		calc_fight()
		calc_reward()

	func prepare_fight():
		set_dangers()
		set_initiatives()

	func set_dangers():
		dangers = []
		
		for index_c in contestants:
			var contestant = Global.get_index_in_array(Global.array.contestants,index_c)
			var value = float(contestant.stats.sum)
			value *= float( size + contestant.reward - 1 ) / float(size)
			
			dangers.append({
				"value": value,
				"index": index_c,
				"team": contestant.team
			})
		
		dangers.sort_custom(Global.Sorter, "sort")
		print("DANGER: ",dangers)
		
		for danger in dangers:
			var contestant = Global.get_index_in_array(Global.array.contestants,danger["index"])
			
			if danger["value"] == dangers[0]["value"] || danger["value"] == dangers[dangers.size()-1]["value"]:
				contestant.assailable = true
			else:
				contestant.assailable = false

	func set_initiatives():
		var max_initiative = -1
		
		for index_c in contestants:
			var contestant = Global.get_index_in_array(Global.array.contestants,index_c)
			var initiative = contestant.get_initiative()
			
			if max_initiative < initiative:
				max_initiative = initiative
		
		for index_c in contestants:
			var contestant = Global.get_index_in_array(Global.array.contestants,index_c)
			var initiative = contestant.get_initiative()
			
			var time_ = float(max_initiative - initiative)
			add_to_timeline(time_, index_c)
		print("timeline: ",timeline)

	func init_hassles():
		hassles = []
		altercations = {}
		
		var index_altercation = 0
		
		for contestant in contestants:
			if !altercations.keys().has(contestant):
				var childs = []
				var parents = [contestant]
				var flag = true
				var counter = 0
				
				while parents.size() > 0 && counter < 10:
					for _i in range(parents.size()-1,-1,-1):
						var parent = Global.get_index_in_array(Global.array.contestants,parents[_i])
						
						for target in parent.targets:
							if !childs.has(target) && !parents.has(target):
								parents.append(target)

						for threat in parent.threats:
							if !childs.has(threat) && !parents.has(threat):
								parents.append(threat)
						
						childs.append(parents.pop_at(_i))
					counter += 1
				
				for child in childs:
					altercations[child] = index_altercation
				
				index_altercation += 1
		
		for _i in index_altercation:
			var indexs = []
			
			for altercation in altercations:
				for key_ in altercations.keys():
					if altercations[key_] == _i && !indexs.has(key_):
						indexs.append(key_)
					
			var hassle = Battleground.Hassle.new()
			hassle.arena = self
			hassle.contestants = indexs
			hassles.append(hassle)
	
		for hassle in hassles:
			hassle.start()

	func du_hast():
		var zero = float(0.0)
		var unfrozens = timeline[zero]
		
		for unfrozen in unfrozens:
			
			Global.get_index_in_array(Global.array.contestants,unfrozen).adopt_decision()
			
		timeline.erase(zero)
		skip_time()

	func skip_time():
		var time_skip = 9999
		
		for time_ in timeline.keys():
			if time_ < time_skip:
				time_skip = time_
				
		var new_time_line = {}
		
		for old_time in timeline.keys():
			var new_time = float(old_time - time_skip)
			new_time_line[new_time] = timeline[old_time]
		
		timeline = new_time_line
		time += time_skip

	func add_to_timeline(time_, contestant_):
		if !timeline.keys().has(time_):
			timeline[time_] = []
		timeline[time_].append(contestant_)

	func calc_fight():
		while contestants.size() > 1:
			du_hast()
			print("timeline: ",timeline)

	func calc_reward():
		var winner = Global.get_index_in_array(Global.array.contestants,contestants[0])
		winner.trophies.append_array(winner_modules)
		
		print("winner kicks: ",winner.kicks)
		print("winner reward: ",winner.reward)
		print("winner modules: ")
		
		for trophie in winner.trophies:
			var module = Global.get_index_in_array(Global.array.modules,trophie)
			module.owner = winner.mechanism
			print(module.stats)
		winner.find_best_gear()

	func new_team(team_name_,contestant_):
		teams[team_name_] = [contestant_]
		contestants.append(contestant_)

	func add_to_team(team_name_,contestant_):
		teams[team_name_].append(contestant_)
		contestants.append(contestant_)

class Contestant:
	var index
	var sdiw
	var point 
	var arena
	var targets = []
	var threats = []
	var rules = {}
	var abilitys = {}
	var in_action = false
	var temper
	var assailable = false 
	var decision = {}
	var kicks = []
	var reward = 1
	var mechanism
	var stats = {}
	var team = ""
	var trophies = []

	func _init(index_, point_):
		index = index_
		point = point_
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.array.danger_types.size()-1)
		rules.danger = Global.array.danger_types[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, Global.list.temper_types.keys().size()-1)
		temper = Global.list.temper_types.keys()[index_r]
		sdiw = Battleground.SDIW.new(self)
		mechanism = Battleground.Mechanism.new(self)
		
		update_all_stats()
		get_basic_abilitys()
		detect_prime()

	func get_basic_abilitys():
		for action in Global.list.ability_help.actions:
			abilitys[action] = []
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, Global.list.ability_help.basic_abilitys[action].size()-1)
			abilitys[action].append(Global.list.ability_help.basic_abilitys[action][index_r])

	func get_initiative():
		var initiative = -1
		var initiatives = []
		
		for key_s in Global.list.SDIW.list["reaction"]:
			var key = Global.list.SDIW.list["reaction"][key_s]
			var index_k = Global.list.SDIW.data_indexs[key]
			
			initiatives.append({
				"value": stats.sqrts[index_k],
				"key": key
			}) 
			
		initiatives.sort_custom(Global.Sorter, "sort")
		
		if arena.rules.initiative == "max":
			initiative = initiatives.pop_back()
		
		return initiative["value"]

	func pick_target():
		var target_count = 1
		targets  = []
		var dangers_ = []
		
		for danger in arena.dangers:
			if danger["team"] != team:
				dangers_.append(danger)
		
		for _i in target_count:
			var options = []
			var target_ = null
			
			match rules.danger:
					"Weak":
						for _j in dangers_.size():
							if dangers_[_j]["value"] == dangers_[0]["value"]:
								options.append(dangers_[_j])
					"Middle":
						for _j in dangers_.size():
							if dangers_[_j]["value"] != dangers_[0]["value"] && dangers_[_j]["value"] != dangers_[dangers_.size()-1]["value"]:
								options.append(dangers_[_j])
						if options.size() < 3:
							options = []
							options.append_array(dangers_)
					"Strong":
						for _j in dangers_.size():
							if dangers_[_j]["value"] == dangers_[dangers_.size()-1]["value"]:
								options.append(dangers_[_j])
			
			#print(rules.danger, options)
			if options.size() > 0:
				var index_r = Global.rng.randi_range(0, options.size()-1)
				target_ = options[index_r]
				dangers_.erase(target_)
				targets.append(target_["index"])
			else:
				print("@ pick target error")

	func adopt_decision():
		if decision.keys().size() == 0:
			var actions = []
			var scale = 2
			
			for action in Global.list.temper_types[temper].keys():
				var amount = Global.list.temper_types[temper][action]
				
				if assailable && action == "Defense":
					amount *= scale
					
				if !assailable && action == "Attack":
					amount *= scale
				
				for _i in amount:
					actions.append(action)
					
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, actions.size()-1)
			decision.action = actions[index_r]
			decision.stage = "Begin"
			
		follow_decision()

	func follow_decision():
		match decision.stage:
			"Begin":
				match decision.action:
					"Defense":
						return
					"Attack":
						pick_target()
						select_attack()
				
						for target in targets:
							Global.get_index_in_array(Global.array.contestants,target).threats.append(index)
			"End":
				complite_action()
				
		decision_next_stage()

	func select_attack():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, abilitys[decision.action].size()-1)
		decision.attack = abilitys[decision.action][index_r]
		var ability = Global.array.abilitys[decision.attack]
		#print("&",Global.abilitys[decision.attack].obj)
		
		Global.rng.randomize()
		var cargo = {}
		cargo.min = 0
		cargo.max = 0
		var time = {}
		time.min = 0
		time.max = 0
		
		for key in ability.obj:
			var capital = key[0]
			cargo.min += Global.list.ability_help.cargo[capital].min
			cargo.max += Global.list.ability_help.cargo[capital].max
			time.min += Global.list.ability_help.time[capital].min
			time.max += Global.list.ability_help.time[capital].max
			
			
		Global.rng.randomize()
		time.roll = Global.rng.randi_range(time.min, time.max)
		#print("$",time, cargo)
		arena.add_to_timeline(time.roll, index)

	func complite_action():
		for target in targets:
			kick(target)
			
		arena.add_to_timeline(7,index)

	func kick(target_):
		if arena.contestants.has(target_):
			scalp(target_)
			kicks.append(target_)
			arena.contestants.erase(target_)
			
			var index_f = -1
			var sprites = Global.node.root.get_node("main/battleground/sprites")
			
			for _i in sprites.get_children().size():
				if sprites.get_children()[_i].name == String(target_):
					index_f = _i

			sprites.remove_child(sprites.get_children()[index_f])

			for _i in arena.dangers.size():
				if arena.dangers[_i]["index"] == target_:
					index_f = _i

			if index_f != -1:
				arena.dangers.remove(index_f)
			
			arena.set_dangers()
			
			for time_ in arena.timeline:
				if arena.timeline[time_].has(target_):
					arena.timeline[time_].erase(target_)
				if arena.timeline[time_].size() == 0:
					arena.timeline.erase(time_)

	func decision_next_stage():
		match decision.stage:
			"End":
				decision = {}
			"Begin":
				decision.stage = "End"

	func scalp(target_):
		var contestant = Global.get_index_in_array(Global.array.contestants,target_)
		reward += contestant.reward
		var module = contestant.mechanism.get_best_module()
		arena.winner_modules.append(module)

	func update_all_stats():
		stats = {}
		stats.short_keys = {}
		stats.long_keys = {}
		stats.sqrts = []
		stats.sum = mechanism.stats.sum + sdiw.stats.sum
		
		for _i in sdiw.stats.sqrts.size():
			var value = mechanism.stats.sqrts[_i]+sdiw.stats.sqrts[_i]
			stats.sqrts.append(value)
			
		for l_key in sdiw.stats.long_keys:
			stats.long_keys[l_key] = mechanism.stats.long_keys[l_key] + sdiw.stats.long_keys[l_key]
		for s_key in sdiw.stats.short_keys:
			stats.short_keys[s_key] = mechanism.stats.short_keys[s_key] + sdiw.stats.short_keys[s_key]

	func find_best_gear():
		print(sdiw.stats)
		print(mechanism.stats)
		var modules = []
		modules.append_array(mechanism.all_modules)
		modules.append_array(trophies)
		var prototype = Prototype.new(modules, self)
		var type = "max"
		prototype.estimator(type)
		print("old: ",index,mechanism.stats)
		mechanism.upgrade_by_prototype(prototype)
		print("new: ",index,mechanism.stats)
		
#
#		print("stats: ",index,stats)
#		print("mech: ",mechanism.stats)
#		print("sdiw: ",sdiw.stats)
	
	func detect_prime():
		var _i = 0
		var sorted = {}
		var values = []
		stats.primes = []
		stats.wingmans = []
		
		for l_key in Global.list.SDIW.long_keys:
			for s_key in Global.list.SDIW.short_keys:
				var obj = {
					"index": _i,
					"stat": Global.list.SDIW.list[l_key][s_key],
					"value": sdiw.stats.sqrts[_i]*sdiw.stats.long_keys[l_key]*sdiw.stats.short_keys[s_key]
					}
					
				if !sorted.keys().has(obj["value"]):
					sorted[obj["value"]] = [obj]
				else:
					sorted[obj["value"]].append(obj)
				_i += 1
		
		var options = []
		
		while stats.primes.size() < Global.list.SDIW.primes || stats.wingmans.size() < Global.list.SDIW.wingmans:
			if options.size() > 0:
				Global.rng.randomize()
				var index_r = Global.rng.randi_range(0, options.size()-1)
				var stat = options[index_r]["stat"]
				options.remove(index_r)
				
				if stats.primes.size() < Global.list.SDIW.primes:
					stats.primes.append(stat)
				else:
					stats.wingmans.append(stat)
			else:
				var max_value = -1
				
				for key in sorted.keys():
					if key > max_value:
						max_value = key
				
				options.append_array(sorted[max_value])
				sorted.erase(max_value)

class SDIW:
	var owner
	var data = []
	var stats = {}

	func _init(owner_):
		owner = owner_
		stats.short_keys = {}
		stats.long_keys = {}
		stats.sqrts = []
		stats.sum = 0
		
		generate()
		set_stats()

	func generate():
		var points_limit = 128
		
		for key in Global.list.SDIW.data_indexs.keys():
			data.append(1)
			stats.sqrts.append(1)
			points_limit -= 1
		
		for _i in points_limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, data.size()-1)
			data[index_r] += 1

	func set_stats():
		stats.sum = 0
		
		for s in Global.list.SDIW.short_keys:
			for l in Global.list.SDIW.long_keys:
				var d = Global.list.SDIW.list[s][l]
				var index_ = Global.list.SDIW.data_indexs[d]
				var value = floor(sqrt(data[index_]))
				stats.sqrts[index_] = value
				stats.sum += value
				
				if !stats.short_keys.keys().has(s):
					stats.short_keys[s] = value
				else:
					stats.short_keys[s] += value
					
				if !stats.long_keys.keys().has(l):
					stats.long_keys[l] = value
				else:
					stats.long_keys[l] += value

	func up_stat(key, inc):
		var index_ = Global.list.SDIW.data_indexs[key]
		var old = floor(sqrt(data[index_]))
		var new = floor(sqrt(data[index_]+inc))
	
		if old != new:
			stats.sqrts[index_] += inc
		
		data[index_] += inc

class Hassle:
	var arena
	var contestants = []
	
	func start():
#		print(contestants)
#		for initiative in arena.initiatives:
#			var index_f = contestants.find(initiative["index"])
#
#			if index_f != -1:
#				print(initiative["index"], arena.Global.array.contestants[initiative["index"]].targets)
		pass

class Ability:
	var index 
	var name 
	var action
	var obj = {}
	
	func _init(obj_):
		index = obj_["Index"]
		name = obj_["Name"]
		action = obj_["Action"]
		
		match action:
			"Defense":
				obj = {
					"Wherewith": obj_["Wherewith"],
					"What": obj_["What"]
				}
			"Attack":
				obj = {
					"Whereby": obj_["Whereby"],
					"How": obj_["How"],
					"What": obj_["What"]
				}

class Behaviour:
	var index

class Strategy:
	var index

class Mechanism:
	var owner
	var all_modules = []
	var modules = {}
	var stats = {}

	func _init(owner_):
		owner = owner_
		stats.short_keys = {}
		stats.long_keys = {}
		stats.sqrts = []
		stats.sum = 0
		
		init_stats()
		generate()

	func init_stats():
		stats.sum = 0
		stats.sqrts = []
		
		for key in Global.list.SDIW.data_indexs.keys():
			stats.sqrts.append(0)
		
		for s in Global.list.SDIW.short_keys:
			stats.short_keys[s] = 0
		for l in Global.list.SDIW.long_keys:
			stats.long_keys[l] = 0

	func generate():
		var points_limit = 49
		var objs = []
		var arr = Global.array.module_types
		
		for type in Global.array.module_types:
			var obj = {}
			obj.owner = self
			obj.type = type
			obj.limit = 4
			obj.prioritys = {}
			
			for key in Global.list.SDIW.short_keys:
				obj.prioritys[key] = 1
			
			objs.append(obj)
			points_limit -= obj.limit
		
		for _i in points_limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, objs.size()-1)
			objs[index_r].limit += 1
		
		for obj in objs:
			obj.index = Global.list.primary_key.module
			var module = Battleground.Module.new(obj)
			Global.array.modules.append(module)
			all_modules.append(obj.index)
			modules[obj.type] = [obj.index]
			Global.list.primary_key.module += 1

	func get_best_module():
		var best_modules = [all_modules[0]]
		
		for _i in range (1,modules.size()):
			var module = Global.get_index_in_array(Global.array.modules,all_modules[_i])
			var module_zero = Global.get_index_in_array(Global.array.modules,best_modules[0])
			
			if module_zero.stats.rating == module.stats.rating:
				best_modules.append(module.index)
			
			if module_zero.stats.rating < module.stats.rating:
				best_modules = [module.index]
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, best_modules.size()-1)
		var result = best_modules.pop_at(index_r)
		all_modules.erase(result)
		modules[Global.get_index_in_array(Global.array.modules,result).type].erase(result)
		return result

	func upgrade_by_prototype(prototype_):
		init_stats()
		
		owner.trophies.append_array(all_modules)
		all_modules = []
		
		for module_type in Global.array.module_types:
			modules[module_type] = prototype_.optimums[module_type]
			
			for new in modules[module_type]:
				var module = Global.get_index_in_array(Global.array.modules,new)
				module.add_to_owner_stats()
				
				if owner.trophies.has(new):
					owner.trophies.erase(new)
					
				all_modules.append(new)
		
		owner.update_all_stats()

class Module:
	var index
	var owner
	var type 
	var key
	var stats = {}
	var rating = {}
	
	func _init(obj_):
		index = obj_.index
		owner = obj_.owner
		type = obj_.type
		stats.sqrts = {}
		stats.sum = 0
		
		match type:
			#Источник энергии
			"Generator":
				key = "replenishment"
			#Маневренность
			"Engine":
				key = "reaction"
			#Обнаружение
			"Sensor":
				key = "outside"
			#Маскировка
			"Disguise":
				key = "inside"
			#Модуль поведения
			"AI":
				key = "capacity"
			#Орудие
			"Gun":
				key = "tension"
			#Системы защиты
			"Protection":
				key = "resistance"
			"Manipulator":
				pass
		
		var options = []
		
		for priority in obj_.prioritys.keys():
			var key_ = Global.list.SDIW.list[key][priority]
			stats.sqrts[key_] = 0
			
			for _i in obj_.prioritys[priority]:
				options.append(key_)
		
		for _i in obj_.limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, options.size()-1)
			stats.sqrts[options[index_r]] += 1
			
		add_to_owner_stats()

	func add_to_owner_stats():
		for stat in stats.sqrts.keys():
			var value = stats.sqrts[stat]
			Global.update_stat(owner,stat,value)
			stats.sum += value
			
		calc_rating()

	func calc_rating():
		var rating = 0
		
		for stat in stats.sqrts.keys():
			rating += pow(stats.sqrts[stat],2)
		
		stats.rating = sqrt(rating)

class Prototype:
	var owner
	var modules = {}
	var optimums = {}
	var not_used = []
	
	func _init(modules_, owner_):
		owner = owner_
		
		for key in Global.array.module_types:
			modules[key] = []
			
		for module in modules_:
			var type = Global.get_index_in_array(Global.array.modules,module).type
			modules[type].append(module)
	
	func estimator(type_):
		var used = []
		
		for key in modules.keys():
			optimums[key] = []
			var a = owner
			var module_amount = owner.mechanism.modules[key].size()
			
			while module_amount > 0:
				var options = []
				
				for index in modules[key]:
					if !used.has(index):
						options = [index]
				
				for index in modules[key]:
					var module = Global.array.modules[index]
					var module_zero = Global.array.modules[options[0]]
					
					match type_:
						"max":
							if module_zero.stats.sum < module.stats.sum:
								options = [module.index]
							if module_zero.stats.sum == module.stats.sum && module.index != module_zero.index:
								options.append(module.index)
				
				while module_amount > 0 && options.size() > 0:
					Global.rng.randomize()
					var index_r = Global.rng.randi_range(0, options.size()-1)
					optimums[key].append(options[index_r])
					used.append(options[index_r])
					options.remove(index_r)
					module_amount -= 1
			
		for key in modules.keys():
			for module in modules[key]:
				if !used.has(module):
					not_used.append(module)
