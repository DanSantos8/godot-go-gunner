class_name HealthComponent extends Node

@onready var HealthLabel = $"../PlayerUI/HealthLabel"
@export var max_health: float = 50.0
var current_health: float

signal health_changed(current: float, max: float, percentage: float)

func _ready():
	current_health = max_health
	_update_ui()

func take_damage(amount: float):
	if current_health <= 0:
		_handle_death()	
		return
		
	current_health = max(0, current_health - amount)
	_update_ui()
	
	var percentage = (current_health / max_health) * 100.0
	health_changed.emit(current_health, max_health, percentage)
	
	
	if current_health <= 0:
		_handle_death()	

func _update_ui():
	if HealthLabel:
		HealthLabel.text = "Health: " + str(int(current_health)) + "/" + str(int(max_health))

func _handle_death():
	var player = get_parent() as Player
	if player:
		MessageBus.emit_battle_event("player_died", {"player": player})
	
	print("💀 Player morreu!")

func is_alive() -> bool:
	return current_health > 0
