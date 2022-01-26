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
	var initiatives = []
	var dangers = []
	var hassles = []
	var alives = []
	var dropouts = []
	var rules = {}
	var altercations = {}
	
	func fight():
		rules.initiative = "max"
		prepare_fight()

	func prepare_fight():
		for _i in contestants.size():
			alives.append(_i)
		
		set_dangers()
		set_initiatives()
		set_targets()
		init_hassles()

	func set_dangers():
		dangers = []
		
		for alive in alives:
			dangers.append({
				"value": contestants[alive].sdiw.stats.sum,
				"index": alive
			})
		
		dangers.sort_custom(Global.Sorter, "sort")
		print("DANGER: ",dangers)

	func set_initiatives():
		initiatives = []
		
		for alive in alives:
			initiatives.append({
				"value": contestants[alive].get_initiative(),
				"index": alive
			})
			
		initiatives.sort_custom(Global.Sorter, "unsort")
		print("INITIATIVES: ",initiatives)

	func set_targets():
		for initiative in initiatives:
			contestants[initiative["index"]].pick_target()
		
		for alive in alives:
			for target in contestants[alive].targets:
				contestants[target].threats.append(alive)

	func init_hassles():
		hassles = []
		altercations = {}
		
		var index_altercation = 0
		
		for alive in alives:
			if !altercations.keys().has(alive):
				var childs = []
				var parents = [alive]
				var flag = true
				var counter = 0
				
				while parents.size() > 0 && counter < 10:
					for _i in range(parents.size()-1,-1,-1):
						var parent = contestants[parents[_i]]
						
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

class Contestant:
	var index
	var sdiw
	var point 
	var arena
	var targets = []
	var threats = []
	var rules = {}
	var ability = []
	
	func _init():
		Global.rng.randomize()
		var index_r = Global.rng.randi_range(0, Global.dangers.size()-1)
		rules.danger = Global.dangers[index_r]
		sdiw = Battleground.SDIW.new(self)
	
	func get_initiative():
		var initiative = -1
		var initiatives = []
		
		for key_s in Global.SDIW.list["reaction"]:
			var key = Global.SDIW.list["reaction"][key_s]
			var index_k = Global.SDIW.data_keys[key]
			
			initiatives.append({
				"value": sdiw.data[index_k],
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
					"weak":
						for _j in dangers_.size():
							if dangers_[_j]["value"] == dangers_[0]["value"]:
								options.append(dangers_[_j])
					"middle":
						for _j in dangers_.size():
							if dangers_[_j]["value"] != dangers_[0]["value"] && dangers_[_j]["value"] != dangers_[dangers_.size()-1]["value"]:
								options.append(dangers_[_j])
					"strong":
						for _j in dangers_.size():
							if dangers_[_j]["value"] == dangers_[dangers_.size()-1]["value"]:
								options.append(dangers_[_j])
			if options.size() > 0:
				var index_r = Global.rng.randi_range(0, options.size()-1)
				target_ = options[index_r]
				dangers_.erase(target_)
				targets.append(target_["index"])
			else:
				print("@error")

class SDIW:
	var data = []
	var stats = {}
	var owner

	func _init(owner_):
		owner = owner_
		stats.short_keys = {}
		stats.long_keys = {}
		stats.sqrts = []
		stats.sum = 0
		
		generate()

	func init_stats():
		stats.sum = 0
		
		for s in Global.SDIW.short_keys:
			for l in Global.SDIW.long_keys:
				var d = Global.SDIW.list[s][l]
				var index_ = Global.SDIW.data_keys[d]
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

	func update_stat(key, inc):
		var index_ = Global.SDIW.data_keys[key]
		var old = floor(sqrt(data[index_]))
		var new = floor(sqrt(data[index_]+inc))
	
		if old != new:
			stats.sqrts[index_] += inc
		
		data[index_] += inc

	func generate():
		var points_cap_ = 100
		var points = 0
		
		for key in Global.SDIW.data_keys.keys():
			data.append(1)
			stats.sqrts.append(1)
			points += 1
		
		while points < points_cap_:
			Global.rng.randomize()
			var index__r = Global.rng.randi_range(0, data.size()-1)
			data[index__r] += 1
			points += 1
		
		init_stats()

class Hassle:
	var arena
	var contestants = []
	
	func start():
		print(contestants)
		for initiative in arena.initiatives:
			var index_f = contestants.find(initiative["index"])
			
			if index_f != -1:
				print(initiative["index"], arena.contestants[initiative["index"]].targets)

class Ability:
	var name
	var type
	var effect 

class Mechanism:
	var modules

class Module:
	var type 
	
	func _init():
		var type
		
		match type:
			"Generator":
				return
			"Engine":
				return
			"Sensor":
				return
			"Disguise":
				return
			"AI":
				return
			"Manipulator":
				return
	
