extends Node2D


class Point:
	var x
	var y
	
	func _init(x_,y_):
		x = x_
		y = y_

class Rectangle:
	var x
	var y
	var w
	var h

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
		
		var ne = Arena.Rectangle.new(x+w/2_,y-h/2_,w/2_,h/2)
		childs.northeast = Arena.QuadTree.new(ne,capacity)
		var nw = Arena.Rectangle.new(x-w/2_,y-h/2_,w/2_,h/2)
		childs.northwest = Arena.QuadTree.new(nw,capacity)
		var se = Arena.Rectangle.new(x+w/2_,y+h/2_,w/2_,h/2)
		childs.southeast = Arena.QuadTree.new(se,capacity)
		var sw = Arena.Rectangle.new(x-w/2_,y+h/2_,w/2_,h/2)
		childs.southwest = Arena.QuadTree.new(sw,capacity)
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
