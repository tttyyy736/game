extends CSGCylinder3D

func interact():
	print("STEP 1: Pill interacted")

	var player = get_node("../../../Player")
	print("STEP 2: Found player: ", player)

	player.take_pill(self)
