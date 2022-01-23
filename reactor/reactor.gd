extends Node2D


class Sector:
	var index
	var grid
	var edges
	var color = -1
	var tile
	var parity
	var neighbors = []
	var all_neighbors = []
	var center_neighbors = []
	var ring_neighbors = []
	var visibility = false
	var ring = -1
