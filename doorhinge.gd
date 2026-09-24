extends Node3D

var is_open := false


@onready var door_sound: AudioStreamPlayer3D = $Door/DoorSound

func interact():

	# Play door sound
	door_sound.play()

	# Open or close door
	if is_open:
		rotation_degrees.y = 0
	else:
		rotation_degrees.y = 90

	is_open = !is_open
