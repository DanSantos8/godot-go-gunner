extends Button
@export var powerup_resource: PowerupResource

func _on_pressed() -> void:
	if powerup_resource:
		var player = _get_player()
		if not player:
			return
		
		if not player.has_stamina(50):
			_show_insufficient_stamina_feedback()
			return
		
		if player.consume_stamina(50):			
			sync_btn_pressed.rpc(powerup_resource.to_dict())
			release_focus()
		else:
			print("❌ [POWERUP_BTN] Falha ao consumir stamina!")

@rpc("authority", "call_local", "reliable")
func sync_btn_pressed(powerup_data: Dictionary):
	var powerup = PowerupResource.from_dict(powerup_data)
	MessageBus.powerup_selected.emit(powerup)

func _get_player() -> Player:
	var current_node = get_parent()
	
	while current_node and not current_node is Player:
		current_node = current_node.get_parent()
	
	return current_node as Player

func _show_insufficient_stamina_feedback():	
	var original_modulate = modulate
	modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.3)

func _ready():
	var player = _get_player()
	if player:
		_update_button_state(player.current_stamina)

func _process(_delta: float):
	var player = _get_player()
	if player:
		_update_button_state(player.current_stamina)

func _update_button_state(current_stamina: int):	
	var has_enough_stamina = current_stamina >= 50
	
	disabled = not has_enough_stamina
	
	modulate.a = 1.0 if has_enough_stamina else 0.5
