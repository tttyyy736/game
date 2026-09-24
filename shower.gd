extends Node3D

var used := false

func interact():
	if used:
		return

	used = true

	var player = get_tree().current_scene.get_node("Player")
	player.take_shower()
