extends Node


class Cell:
	var index
	var grid
	var tile
	var neighbors = []
	var roads = []
	var highways = []
	var all_neighbor_cells = []
	var districts = []
	var crossroad = -1
	var city = -1
	var cluster = -1
	var coast = -1

class Highway:
	var index
	var roads = []
	var crossroads = []
	var cells = []
	var branchs = []

class Coast:
	var index
	var road
	var coast
	var cells = []
	var neighbors = []
	var cluster = -1

class Cluster:
	var index
	var coasts = []
	var neighbors = []
