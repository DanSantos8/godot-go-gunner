extends HBoxContainer

func _ready():
	MessageBus.end_turn.connect(_clean_up_powerup_feedback)
	MessageBus.powerup_selected.connect(_add_powerup_feedback)

func _add_powerup_feedback(powerup: PowerupResource):
	var label = Label.new()
	label.text = powerup.powerup_name
	
	# Size
	label.custom_minimum_size = Vector2(30, 30)
	
	# Background preto
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.BLACK
	label.add_theme_stylebox_override("normal", style_box)
	
	# Centralizar texto (opcional)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	add_child(label)

func _clean_up_powerup_feedback():
	queue_free()
