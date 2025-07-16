extends Button

@export var powerup_resource: PowerupResource

func _on_pressed() -> void:
	if powerup_resource:
		MessageBus.powerup_selected.emit(powerup_resource)
