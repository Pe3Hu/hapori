extends Node


class Rialto:
	var prices = {
		"loot orb": {
			"herb breed 0": 16,
			"herb breed 1": 32,
			"herb breed 2": 48
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
		lot.index = Global.list.primary_key.lot
		lot.price.deal = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.benchmark)
		lot.price.min = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.min)
		lot.price.max = prices[lot.what][lot.where]*(1+lot.owner.greed.markup[lot.role]+lot.owner.greed.max)
		var index = findmarket_(lot)
		lot.market = markets[index]
		markets[index].lots[lot.role].append(lot)
		markets[index].requirements_check()
		
		lots[lot.role].append(lot)
		Global.list.primary_key.lot += 1
	
	func findmarket_(lot):
		var exist_flag = false
		var market = null
		
		for market_ in markets:
			if market_.subject == lot.what && market_.where == lot.where:
				exist_flag = true
				market = market_
		
		if !exist_flag:
			market = Bourse.Market.new()
			market.subject = lot.what
			market.where = lot.where
			market.price = prices[lot.what]
			market.timer.current = 0
			market.timer.max = 2
			market.timer.on = false
			markets.append(market)
		
		var index_f = markets.find(market)
		return index_f

	func time_flow(delta):
		for market in markets:
			if market.timer.on:
				market.conduct(delta)

class Market: 
	var subject = null
	var where = null
	var price = null
	var lots = {
		"buy": [],
		"sell": []
	}
	var requirements = {
		"buy": 1,
		"sell": 1
	}
	var timer = {}
	
	func requirements_check():
		var flag = true
		
		for key in lots.keys():
			flag = flag && lots[key].size() > requirements[key]
			#print(where," requirements check ", requirements[key], key, lots[key].size())
		
		timer.on = flag
	
	func conduct(delta):
		timer.current += delta
		
		if timer.current >= timer.max:
			timer.current = 0
			#print("!!!!!!!!!!!!!!!!!! conduct ", where)
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
					#print("after deal ",deal["sell"].owner.index,deal["sell"].owner.bag.item_indexs,deal["buy"].owner.index,deal["buy"].owner.bag.item_indexs)
					#print(deal["sell"].price.deal, " outlay ", deal["sell"].outlay)
					#print(deal["sell"].owner.greed,deal["buy"].owner.greed)
					
					options[keys[0]].remove(_i)
					options[keys[1]].remove(index_r)
				_i -= 1
				
			lots["sell"] = options["sell"]
			lots["buy"] = options["buy"]
			requirements_check()
	
	func deal_check(deal):
		var current = deal["sell"].price.deal
		var flag = current < deal["buy"].price.max 
		#print("%deal check sell ", deal["sell"].price, " buy", deal["buy"].price)
		return flag

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
	var registered = false
