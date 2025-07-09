extends Area2D	

class_name ExplosionArea

@export var destruction_data: DestructionData
@export var base_damage: float = 25.0

func _ready():
	if not destruction_data:
		destruction_data = DestructionData.new()
		destruction_data.type = DestructionData.DestructionType.CIRCULAR
		destruction_data.radius = 15.0

func _on_body_entered(body: Node2D) -> void:
	# print("💥 EXPLOSION AREA detectou: ", body.name, " | Tipo: ", body.get_class())
	
	if body.name == "Terrain":
		# print("🌍 Destruindo terreno...")
		var terrain_container = get_tree().get_first_node_in_group("terrain_manager")
		
		if terrain_container:
			terrain_container.apply_destruction(global_position, destruction_data)
		else:
			print("TerrainContainer não encontrado!")
		
		get_parent().queue_free()
	
	elif body is Player:
		# print("🎯 Player detectado!")
		var health_component = body.get_node("HealthComponent")
		
		if health_component:
			health_component.take_damage(base_damage)
			# print("💥 Player ", body.name, " levou ", base_damage, " de dano!")
		else:
			# print("❌ HealthComponent não encontrado!")
			pass
		
		get_parent().queue_free()
