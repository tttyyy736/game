extends Node3D

func interact():
	var player = get_tree().current_scene.get_node("Player")

	if player.current_objective != 6:
		return

	player.end_game()
