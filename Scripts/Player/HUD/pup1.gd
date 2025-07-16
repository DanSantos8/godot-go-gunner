extends Button
@export var powerup_resource: PowerupResource

func _on_pressed() -> void:
	if powerup_resource:
		print("Pressionado")
		powerup_resource.add_powerup()
