extends Node



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
