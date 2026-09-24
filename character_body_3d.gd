extends CharacterBody3D
@onready var shower_sound: AudioStreamPlayer = $ShowerSound
@onready var food_sound: AudioStreamPlayer = $FoodSound
# =========================
# PLAYER SETTINGS
# =========================
@onready var interact_hint = $"../UI/InteractHint"
@onready var noose = $"../House/Noose"
@export var speed := 2.3
@export var mouse_sensitivity := 0.002
var ending := false
@onready var pill_sound: AudioStreamPlayer = $PillSound
var in_bed := true
var current_objective := 1
@onready var thanks_text = $"../UI/ThanksText"

# =========================
# NODE REFERENCES
# =========================

@onready var head = $Head
@onready var raycast = $Head/Camera3D/RayCast3D

@onready var objective_text = $"../UI/ObjectiveText"
@onready var fade_screen = $"../UI/FadeScreen"

@onready var yellow_light: OmniLight3D = $"../MeshInstance3D/OmniLight3D"


# =========================
# STARTUP
# =========================

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Yellow light starts off
	yellow_light.light_energy = 0.0

	# Start lying sideways in bed
	if in_bed:
		head.rotation_degrees.z = -90
		rotation_degrees.y = 90
	noose.hide()
	
	show_interact_hint()


# =========================
# INPUT
# =========================

func _unhandled_input(event):

	# Click inside the game to recapture the mouse
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Mouse look
# Camera is locked while lying in bed
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not in_bed:
			rotate_y(-event.relative.x * mouse_sensitivity)

			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(
				head.rotation.x,
				-1.5,
				1.5
		)

	# Escape releases mouse
	

	# Get out of bed
	if in_bed and event.is_action_pressed("interact"):
		get_out_of_bed()
		return

	# Normal interaction
	if event.is_action_pressed("interact"):
		interact()


# =========================
# MOVEMENT
# =========================

func _physics_process(delta):

	# No movement while lying in bed
	if in_bed:
		velocity = Vector3.ZERO
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	var input_dir = Input.get_vector(
		"left",
		"right",
		"forward",
		"backward"
	)
	if ending:
		velocity = Vector3.ZERO
		return

	var direction = (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	if raycast.is_colliding():
		print("LOOKING AT: ", raycast.get_collider())


# =========================
# GENERAL INTERACTION
# =========================

func interact():
	if ending:
		return

	if not raycast.is_colliding():
		return

	var object = raycast.get_collider()

	if not is_instance_valid(object):
		return

	# Save the parent before interacting.
	# Some interactions may delete the collider.
	var parent = object.get_parent()

	# Interact directly with object
	if object.has_method("interact"):
		object.interact()
		return

	# Otherwise try its parent
	if is_instance_valid(parent):
		if parent.has_method("interact"):
			parent.interact()


# =========================
# OBJECTIVE 1
# GET OUT OF BED
# =========================

func get_out_of_bed():

	if not in_bed:
		return

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Rotate upright
	tween.tween_property(
		head,
		"rotation_degrees:z",
		0.0,
		1.2
	)

	# Move away from bed
	tween.parallel().tween_property(
		self,
		"global_position:x",
		global_position.x + 0.75,
		1.2
	)

	await tween.finished

	in_bed = false
	current_objective = 2

	# Fade Objective 1 away
	await hide_objective()

	# Pause
	await get_tree().create_timer(2.0).timeout

	# Objective 2
	await show_objective(
		"Objective 2: Take your medication."
	)


# =========================
# OBJECTIVE 2
# TAKE MEDICATION
# =========================

func take_pill(pill):

	# Cannot take pills before Objective 2
	if current_objective != 2:
		return

	if not is_instance_valid(pill):
		return

	# Lock immediately so interaction can't trigger twice
	current_objective = 3

# Play medication sound
	# Play medication sound
	pill_sound.play()

# Stop it after 3 seconds
	get_tree().create_timer(1.2).timeout.connect(
		func(): pill_sound.stop()
)

# Fade screen to black
	await fade_to_black()

	# Hide Objective 2
	objective_text.hide()

	# Disable RayCast before deleting its collider
	raycast.enabled = false

	# Save parent before deleting anything
	var pills_parent = pill.get_parent()

	# Delete bottle/pill/cap hierarchy
	if is_instance_valid(pills_parent):
		pills_parent.queue_free()

	# Let Godot finish deleting it
	await get_tree().process_frame

	# Restore RayCast
	raycast.enabled = true

	# Stay black briefly
	await get_tree().create_timer(0.75).timeout

	# Fade room back in
	await fade_from_black()

	# Pause
	await get_tree().create_timer(2.0).timeout

	# Objective 3
	await show_objective(
		"Objective 3: Eat something."
	)


# =========================
# OBJECTIVE 3
# EAT FOOD
# =========================

func eat_food(food):

	# Cannot eat before Objective 3
	if current_objective != 3:
		return

	if not is_instance_valid(food):
		return

	# Lock immediately
	current_objective = 4

# Play eating sound
	food_sound.play()

# Fade to black
	await fade_to_black()

	# Hide Objective 3
	objective_text.hide()

	# Disable RayCast before deleting food
	raycast.enabled = false

	if is_instance_valid(food):
		food.queue_free()

	# Allow deletion to finish
	await get_tree().process_frame

	raycast.enabled = true

	# Stay black briefly
	await get_tree().create_timer(0.75).timeout

	# Fade back in
	await fade_from_black()

	# Pause
	await get_tree().create_timer(2.0).timeout

	# Objective 4
	await show_objective(
		"Objective 4: Take a shower."
	)


# =========================
# OBJECTIVE 4
# TAKE A SHOWER
# =========================

func take_shower():

	if current_objective != 4:
		return

	current_objective = 5

	# Fade to black
	await fade_to_black()

	# Hide Objective 4
	objective_text.hide()

	# Start shower sound
	shower_sound.play()

	# Stay black while shower runs
	await get_tree().create_timer(4.0).timeout

	# Stop shower sound
	shower_sound.stop()

	# Fade back into bathroom
	await fade_from_black()

	# Wait before Objective 5
	await get_tree().create_timer(2.0).timeout

	# Continue with the rest of your existing function...

	# =========================
	# OBJECTIVE 5
	# GET DRESSED
	# =========================

	await show_objective(
		"Objective 5: Get dressed."
	)

	# Leave it visible for 3 seconds
	await get_tree().create_timer(3.0).timeout

	# Fade "Get dressed" away
	await hide_objective()

	# =========================
	# NEVERMIND
	# =========================

	await show_objective("Nevermind.")

	# Leave it visible for 3 seconds
	await get_tree().create_timer(3.0).timeout

	# Fade it away
	await hide_objective()

	# =========================
	# CALL IT A DAY
	# =========================

	# Set the light color
	yellow_light.light_color = Color(1.0, 1.0, 0.0)

# Slowly brighten the yellow light
	var light_fade = create_tween()
	light_fade.set_trans(Tween.TRANS_SINE)
	light_fade.set_ease(Tween.EASE_IN_OUT)

	light_fade.tween_property(
		yellow_light,
		"light_energy",
		20.0,
		5.0
)

# Advance state
	current_objective = 6

# Reveal the noose
	noose.show()

# Final objective
	await show_objective("Call it a day.")

# Wait for the light to finish brightening
	await light_fade.finished


# =========================
# OBJECTIVE UI HELPERS
# =========================

func show_objective(text: String):

	objective_text.text = text
	objective_text.modulate = Color(1, 1, 1, 0)
	objective_text.show()

	var tween = create_tween()

	tween.tween_property(
		objective_text,
		"modulate",
		Color(1, 1, 1, 1),
		1.0
	)

	await tween.finished


func hide_objective():

	var tween = create_tween()

	tween.tween_property(
		objective_text,
		"modulate:a",
		0.0,
		1.0
	)

	await tween.finished

	objective_text.hide()


# =========================
# SCREEN FADE HELPERS
# =========================

func fade_to_black():

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_screen,
		"modulate",
		Color(1, 1, 1, 1),
		1.0
	)

	await tween.finished


func fade_from_black():

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_screen,
		"modulate",
		Color(1, 1, 1, 0),
		1.0
	)

	await tween.finished
	
func start_ending(camera_point: Marker3D):

	if current_objective != 6:
		return

	if ending:
		return

	ending = true

	# Stop movement
	velocity = Vector3.ZERO

	# Hide the objective
	await hide_objective()

	# Move toward the predetermined ending shot
	var ending_tween = create_tween()
	ending_tween.set_trans(Tween.TRANS_SINE)
	ending_tween.set_ease(Tween.EASE_IN_OUT)

	ending_tween.tween_property(
		self,
		"global_position",
		camera_point.global_position,
		2.5
	)

	await ending_tween.finished

	# Hold on the shot
	await get_tree().create_timer(2.0).timeout

	# Cut to black
	await fade_to_black()
	
func end_game():

	# Prevent any more interaction
	current_objective = 7
	velocity = Vector3.ZERO

	# Hide "Call it a day."
	objective_text.hide()

	# Cut instantly to black
	fade_screen.modulate = Color(1, 1, 1, 1)

	# Wait in complete darkness
	await get_tree().create_timer(2.0).timeout

	# Fade in "Thanks for playing."
	thanks_text.modulate = Color(1, 1, 1, 0)
	thanks_text.show()

	var thanks_fade = create_tween()
	thanks_fade.set_trans(Tween.TRANS_SINE)
	thanks_fade.set_ease(Tween.EASE_IN_OUT)

	thanks_fade.tween_property(
		thanks_text,
		"modulate:a",
		1.0,
		3.0
	)

	await thanks_fade.finished
	
func show_interact_hint():

	# Wait 3 seconds after game starts
	await get_tree().create_timer(3.0).timeout

	# Fade in
	interact_hint.modulate.a = 0.0
	interact_hint.show()

	var fade_in = create_tween()
	fade_in.tween_property(
		interact_hint,
		"modulate:a",
		1.0,
		1.0
	)

	await fade_in.finished

	# Stay visible for 3 seconds
	await get_tree().create_timer(3.0).timeout

	# Fade away
	var fade_out = create_tween()
	fade_out.tween_property(
		interact_hint,
		"modulate:a",
		0.0,
		1.0
	)

	await fade_out.finished

	interact_hint.hide()
