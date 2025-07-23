extends Label

func _ready() -> void:
	# Conecta ao MessageBus
	MessageBus.damage_taken.connect(_on_damage_taken)
	
	# Configurações iniciais
	visible = false
	
	# Ajusta tamanho da fonte para mundo 2D (pode preciar ajustar)
	add_theme_font_size_override("font_size", 20)

func _on_damage_taken(damage_amount: float, world_position: Vector2):
	# Reset completo do estado
	modulate = Color.WHITE
	global_position = world_position
	
	text = str(damage_amount)
	visible = true
	
	# Tween mais seguro
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + Vector2(0, -30), 1.0)
	
	await tween.finished
	visible = false
