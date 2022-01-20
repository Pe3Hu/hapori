extends Node


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
