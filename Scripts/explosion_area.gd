extends Area2D
class_name ExplosionArea

func _on_body_entered(body: Node2D) -> void:
	"""Detecta Terrain (StaticBody2D) e outros physics bodies"""
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão com BODY...")
	print("[BODY DETECTADO]: ", body.name)
	
	# Captura dados do projétil para cálculo vetorial
	var projectile = get_parent()
	var impact_velocity = projectile.linear_velocity
	var impact_direction = impact_velocity.normalized()
	var impact_position = global_position
	
	print("🎯 Impact velocity: ", impact_velocity)
	print("📐 Impact direction: ", impact_direction)
	print("📍 Impact position: ", impact_position)
	
	# Calcula posição resultante do impacto vetorial
	var push_distance = 24.0
	var result_position = impact_position + (impact_direction * push_distance)
	
	var player_id = -1
	
	if body is Player:
		player_id = body.network_id
		# Dispara collision com player
		sync_projectile_collision.rpc("Player", global_position, player_id)
		# Dispara collision com terrain na posição calculada
		sync_projectile_collision.rpc("Terrain", result_position, -1)
	else:
		var entity_type = EntityHelper.get_entity_type(body)
		sync_projectile_collision.rpc(entity_type, global_position, player_id)

@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id: int):
	MessageBus.projectile_collision.emit(body_name, position, player_id)
	
	var projectile = get_parent()
	if projectile:
		get_parent().queue_free()
