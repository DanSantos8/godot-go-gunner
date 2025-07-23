extends Label

func _ready() -> void:
	MessageBus.damage_taken.connect(_on_damage_taken)
	
	visible = false
	
	add_theme_font_size_override("font_size", 20)

func _on_damage_taken(damage_amount: float, target_id: int):
	if target_id != get_parent().get_parent().network_id:
		return
		
	modulate = Color.WHITE
	global_position = get_parent().get_parent().global_position
	
	text = str(damage_amount)
	visible = true
	
	# Tween mais seguro
	await get_tree().create_timer(1).timeout
	visible = false
