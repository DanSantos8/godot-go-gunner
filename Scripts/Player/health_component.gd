class_name HealthComponent extends Node

@onready var HealthLabel = $"../PlayerUI/HealthLabel"
var _fallback_max_health: float = 50.0

@export var character_resource: CharacterResource:
	set(resource):
		character_resource = resource
		if character_resource and is_inside_tree():
			max_health = character_resource.health
			current_health = max_health
			_update_ui()

var max_health: float:
	get:
		if (character_resource):
			return character_resource.health
		else:
			return 50.0
	set(value):
		if not character_resource:
			_fallback_max_health = value


var current_health: float:
	set(value):
		var old_health = current_health
		current_health = max(0, min(value, max_health))
		
		if current_health != old_health:
			_update_ui()
			
			var percentage = (current_health / max_health) * 100.0
			health_changed.emit(current_health, max_health, percentage)
			
			if current_health <= 0 and old_health > 0:
				_handle_death()

signal health_changed(current: float, max: float, percentage: float)

func _ready():
	MessageBus.projectile_collided_with_player.connect(_take_damage)
	
	if character_resource:
		current_health = max_health
	else:
		current_health = _fallback_max_health
	
	_update_ui()

func _take_damage(target_id: int, damage_amount: float, position: Vector2):
	MessageBus.damage_taken.emit(damage_amount, get_parent().global_position)
	
	if target_id != get_parent().network_id:
		return
		
	if current_health <= 0:
		_handle_death()
		return
		
	current_health -= damage_amount

func _update_ui():
	if HealthLabel:
		HealthLabel.text = "Health: " + str(int(current_health)) + "/" + str(int(max_health))

func _handle_death():
	var player = get_parent() as Player
	if player:
		MessageBus.game_over.emit(BattleManager.get_current_player())
	
	print("💀 Player morreu!")

func is_alive() -> bool:
	return current_health > 0
