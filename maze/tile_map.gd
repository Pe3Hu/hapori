extends TileMap



#func _unhandled_input(event):
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT and event.pressed:
#			var vec = event.position.rotated(deg2rad(-45))
#			var clicked_cell = Global.maze.map.world_to_map(vec)
#			var index = Global.maze.convert_grid(clicked_cell)
#			print(event.position,vec,index,clicked_cell, Global.maze.cells[index].neighbors)
