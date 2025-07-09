extends CanvasLayer

@onready var PlayAgainBtn = $Container/PlayAgain
@onready var QuitBtn = $Container/Quit

func _ready() -> void:
	MessageBus.game_over.connect(_show_game_over_menu)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	PlayAgainBtn.pressed.connect(_on_play_again_pressed)
	QuitBtn.pressed.connect(_on_quit_pressed)


func _show_game_over_menu(winner: Player):
	visible = true
	get_tree().paused = true
	
func _on_play_again_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()
