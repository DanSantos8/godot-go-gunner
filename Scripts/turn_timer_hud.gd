extends CanvasLayer

@onready var TimerLabel: Label = $VBoxContainer/TimerLabel
@onready var PlayerTurnLabel: Label = $VBoxContainer/PlayerTurnLabel

func _ready():
	MessageBus.turn_timer.connect(_update_timer_label)
	
func _process(delta: float) -> void:
	_update_player_turn_label()
	
func _update_timer_label(seconds: int):
	TimerLabel.text = "Remaining Time: " + str(roundi(seconds))

func _update_player_turn_label():
	PlayerTurnLabel.text = BattleManager.get_current_player().name
