extends Area2D
class_name ExplosionArea

# Configurações de impacto
@export var penetration_distance: float = 24.0

func _on_body_entered(body: Node2D) -> void:
	"""Detecta colisões e calcula impacto no terreno"""
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão...")
	print("[BODY DETECTADO]: ", body.name, " (", body.get_class(), ")")
	
	# Captura dados do projétil
	var projectile = get_parent()
	var impact_data = _calculate_impact_data(projectile, body)
	
	var player_id = -1
	
	if body is Player:
		player_id = body.network_id
		print("🎯 Player atingido: ", body.name, " (ID: ", player_id, ")")
		
		# 1. Aplica dano no player
		sync_projectile_collision.rpc("Player", global_position, player_id)
		
		# 2. Calcula cratera no terreno
		var crater_position = _calculate_terrain_crater_position(body, impact_data)
		sync_projectile_collision.rpc("Terrain", crater_position, -1)
		
		print("🕳️ Cratera será criada em: ", crater_position)
		
	else:
		# Colisão com terreno ou outros objetos
		var entity_type = EntityHelper.get_entity_type(body)
		sync_projectile_collision.rpc(entity_type, global_position, player_id)

func _calculate_impact_data(projectile: RigidBody2D, target_body: Node2D) -> Dictionary:
	"""Calcula dados do impacto para usar nos cálculos"""
	
	var impact_velocity = projectile.linear_velocity
	var impact_direction = impact_velocity.normalized()
	var impact_position = global_position
	
	var data = {
		"direction": impact_direction,
		"position": impact_position
	}
	
	print("📊 Impact data: direção=", impact_direction)
	return data

func _calculate_terrain_crater_position(player: Player, impact_data: Dictionary) -> Vector2:
	"""Calcula onde criar a cratera no terreno baseado no impacto"""
	
	# 1. Pega dimensões do player
	var player_bounds = _get_player_bounds(player)
	var player_radius = player_bounds.x  # Usa largura como raio aproximado
	
	# 2. Posição da cratera: player center + penetração fixa
	var impact_direction = impact_data.direction
	var crater_position = player.global_position + (impact_direction * penetration_distance)
	
	# 3. Validação: verifica se posição é válida
	var validated_pos = _validate_crater_position(crater_position, player.global_position, impact_direction)
	
	print("🎯 Cálculo cratera:")
	print("  Player radius: ", player_radius)
	print("  Penetration distance: ", penetration_distance, " (fixo)")
	print("  Posição final: ", validated_pos)
	
	return validated_pos

func _get_player_bounds(player: Player) -> Vector2:
	"""Pega dimensões aproximadas do player"""
	
	# Tenta pegar do CollisionShape2D
	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		
		if shape is CapsuleShape2D:
			return Vector2(shape.radius * 2, shape.height)
		elif shape is RectangleShape2D:
			return shape.size
		elif shape is CircleShape2D:
			var radius = shape.radius
			return Vector2(radius * 2, radius * 2)
	
	# Fallback: tamanho padrão
	print("⚠️ Usando tamanho padrão do player")
	return Vector2(16, 32)  # Tamanho típico de character

func _validate_crater_position(calculated_pos: Vector2, player_pos: Vector2, impact_direction: Vector2) -> Vector2:
	"""Valida e ajusta posição da cratera se necessário"""
	
	# Verifica se a posição está muito longe do player (sanity check)
	var distance_from_player = calculated_pos.distance_to(player_pos)
	if distance_from_player > penetration_distance * 2:
		print("⚠️ Posição muito longe, ajustando...")
		return player_pos + (impact_direction * penetration_distance)
	
	# TODO: verificar se realmente tem terreno na posição
	# Por enquanto, confia na posição calculada
	
	return calculated_pos

# ===== UTILITY METHODS =====

func get_impact_stats() -> Dictionary:
	"""Retorna estatísticas para debug"""
	return {
		"penetration_distance": penetration_distance
	}

@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id: int):
	"""Sincroniza colisão via network"""
	MessageBus.projectile_collision.emit(body_name, position, player_id)
	
	var projectile = get_parent()
	if projectile:
		projectile.queue_free()
