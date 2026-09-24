extends CSGCylinder3D

func interact():
	var player = get_tree().current_scene.get_node("Player")
	player.eat_food(self)
