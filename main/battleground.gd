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
		
		for contestant in contestants:
			var value = float(Global.battleground.contestants[contestant].stats.sum)
			value *= float( size + Global.battleground.contestants[contestant].reward - 1 ) / float(size)
			
			dangers.append({
				"value": value,
				"index": contestant
			})
		
		dangers.sort_custom(Global.Sorter, "sort")
		print("DANGER: ",dangers)
		
		for danger in dangers:
			if danger["value"] == dangers[0]["value"] || danger["value"] == dangers[dangers.size()-1]["value"]:
				Global.battleground.contestants[danger["index"]].assailable = true
			else:
				Global.battleground.contestants[danger["index"]].assailable = false

	func set_initiatives():
		var max_initiative = -1
		
		for contestant in contestants:
			var initiative = Global.battleground.contestants[contestant].get_initiative()
			
			if max_initiative < initiative:
				max_initiative = initiative
		
		for contestant in contestants:
			var initiative = Global.battleground.contestants[contestant].get_initiative()
			
			var time_ = max_initiative - initiative
			add_to_timeline(time_, contestant)
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
						var parent = Global.battleground.contestants[parents[_i]]
						
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
		var unfrozens = timeline[0.0]
		
		for unfrozen in unfrozens:
			Global.battleground.contestants[unfrozen].adopt_decision()
			
		timeline.erase(0)
		skip_time()

	func skip_time():
		var time_skip = 9999
		
		for time_ in timeline.keys():
			if time_ < time_skip:
				time_skip = time_
				
		var new_time_line = {}
		
		for old_time in timeline.keys():
			var new_time = old_time - time_skip
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
		var winner = Global.battleground.contestants[contestants[0]]
		print("winner kicks: ",winner.kicks)
		print("winner reward: ",winner.reward)
		print("winner modules: ")
		for winner_module in winner_modules:
			print(winner_module.stats.sqrts)
	
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

	func _init(index_, point_):
		index = index_
		point = point_
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.dangers.size()-1)
		rules.danger = Global.dangers[index_r]
		Global.rng.randomize()
		index_r = Global.rng.randi_range(0, Global.tempers.keys().size()-1)
		temper = Global.tempers.keys()[index_r]
		sdiw = Battleground.SDIW.new(self)
		mechanism = Battleground.Mechanism.new(self)
		
		update_all_stats()
		get_basic_abilitys()

	func get_basic_abilitys():
		for action in Global.ability_help.actions:
			abilitys[action] = []
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, Global.ability_help.basic_abilitys[action].size()-1)
			abilitys[action].append(Global.ability_help.basic_abilitys[action][index_r])

	func get_initiative():
		var initiative = -1
		var initiatives = []
		
		for key_s in Global.SDIW.list["reaction"]:
			var key = Global.SDIW.list["reaction"][key_s]
			var index_k = Global.SDIW.data_indexs[key]
			
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
			if danger["index"] != index:
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
			
			for action in Global.tempers[temper].keys():
				var amount = Global.tempers[temper][action]
				
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
							Global.battleground.contestants[target].threats.append(index)
			"End":
				complite_action()
				
		decision_next_stage()

	func select_attack():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, abilitys[decision.action].size()-1)
		decision.attack = abilitys[decision.action][index_r]
		var ability = Global.abilitys[decision.attack]
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
			cargo.min += Global.ability_help.cargo[capital].min
			cargo.max += Global.ability_help.cargo[capital].max
			time.min += Global.ability_help.time[capital].min
			time.max += Global.ability_help.time[capital].max
			
			
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
			
#			var index_f  = -1
#
#			for _i in arena.dangers.size():
#				if arena.dangers[_i]["index"] == target_:
#					index_f = _i
#
#			if index_f != -1:
#				arena.dangers.remove(index_f)
			
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
		reward += Global.battleground.contestants[target_].reward
		var module = Global.battleground.contestants[target_].mechanism.get_best_module()
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
			
		print(index,stats)

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
		
		for key in Global.SDIW.data_indexs.keys():
			data.append(1)
			stats.sqrts.append(1)
			points_limit -= 1
		
		for _i in points_limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, data.size()-1)
			data[index_r] += 1

	func set_stats():
		stats.sum = 0
		
		for s in Global.SDIW.short_keys:
			for l in Global.SDIW.long_keys:
				var d = Global.SDIW.list[s][l]
				var index_ = Global.SDIW.data_indexs[d]
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
		var index_ = Global.SDIW.data_indexs[key]
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
#				print(initiative["index"], arena.Global.battleground.contestants[initiative["index"]].targets)
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
	var modules = []
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
		
		for key in Global.SDIW.data_indexs.keys():
			stats.sqrts.append(0)
		
		for s in Global.SDIW.short_keys:
			stats.short_keys[s] = 0
		for l in Global.SDIW.long_keys:
			stats.long_keys[l] = 0

	func generate():
		var points_limit = 49
		var objs = []
		var arr = Global.modules
		
		for type in Global.modules:
			var obj = {}
			obj.owner = self
			obj.type = type
			obj.limit = 4
			obj.prioritys = {}
			
			for key in Global.SDIW.short_keys:
				obj.prioritys[key] = 1
			
			objs.append(obj)
			points_limit -= obj.limit
		
		for _i in points_limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, objs.size()-1)
			objs[index_r].limit += 1
		
		for obj in objs:
			var module = Battleground.Module.new(obj)
			modules.append(module)

	func get_best_module():
		var best_modules = [modules[0]]
		
		for _i in range (1,modules.size()):
			var module = modules[_i]
			
			if best_modules[0].stats.sum == module.stats.sum:
				best_modules.append(module)
			
			if best_modules[0].stats.sum < module.stats.sum:
				best_modules = [module]
		
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, best_modules.size()-1)
		var result = best_modules.pop_at(index_r)
		return result

class Module:
	var owner
	var type 
	var key
	var stats = {}
	
	func _init(obj_):
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
			var key_ = Global.SDIW.list[key][priority]
			stats.sqrts[key_] = 0
			
			for _i in obj_.prioritys[priority]:
				options.append(key_)
		
		for _i in obj_.limit:
			Global.rng.randomize()
			var index_r = Global.rng.randi_range(0, options.size()-1)
			stats.sqrts[options[index_r]] += 1
		
		for stat in stats.sqrts.keys():
			var value = stats.sqrts[stat]
			Global.update_stat(owner,stat,value)
			stats.sum += value
