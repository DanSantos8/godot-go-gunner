extends Button
@export var powerup_resource: PowerupResource

func _on_pressed() -> void:
	if powerup_resource:
		# Serializa antes de enviar
		sync_btn_pressed.rpc(powerup_resource.to_dict())
		release_focus()

@rpc("authority", "call_local", "reliable")
func sync_btn_pressed(powerup_data: Dictionary):
	# Reconstroi o Resource em cada client
	var powerup = PowerupResource.from_dict(powerup_data)
	MessageBus.powerup_selected.emit(powerup)
