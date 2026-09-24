extends Control

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(resume_game)
	quit_button.pressed.connect(quit_game)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()


func pause_game():
	get_tree().paused = true
	show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume_game():
	get_tree().paused = false
	hide()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func quit_game():
	get_tree().quit()
