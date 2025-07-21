extends Area2D
class_name ExplosionArea

# Configurações de explosão
@export var explosion_radius: float = 30.0
@export var terrain_search_distance: float = 30.0  # Reduzido!

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
		
		# HÍBRIDA: Explosão no impacto + Cratera no terreno abaixo
		var explosion_position = global_position  # Onde projétil colidiu
		var crater_position = _find_terrain_below_player(body)  # Terreno abaixo do player
		
		# 1. Aplica dano no player (explosão no ponto de impacto)
		sync_projectile_collision.rpc("Player", explosion_position, player_id)
		
		# 2. Cria cratera no terreno (sempre abaixo do player)
		if crater_position != Vector2.ZERO:
			sync_projectile_collision.rpc("Terrain", crater_position, -1)
			print("💥 Explosão em: ", explosion_position)
			print("🕳️ Cratera criada em: ", crater_position)
		else:
			print("⚠️ Terreno não encontrado abaixo do player")
		
	else:
		# Colisão com terreno ou outros objetos
		var entity_type = EntityHelper.get_entity_type(body)
		sync_projectile_collision.rpc(entity_type, global_position, player_id)

func _calculate_impact_data(projectile: RigidBody2D, target_body: Node2D) -> Dictionary:
	"""Calcula dados básicos do impacto"""
	
	var impact_position = global_position
	var impact_velocity = projectile.linear_velocity
	
	var data = {
		"position": impact_position,
		"velocity": impact_velocity
	}
	
	print("📊 Impact data: posição=", impact_position)
	return data



func _find_terrain_below_player(player: Player) -> Vector2:
	"""Encontra superfície do terreno próxima ao player"""
	
	# Começa na BASE do player (pés), não no centro
	var player_bounds = _get_player_bounds(player)
	var player_bottom = player.global_position + Vector2(0, player_bounds.y / 2)
	
	var search_start = player_bottom
	var search_end = player_bottom + Vector2(0, terrain_search_distance)
	
	print("🔍 Procurando SUPERFÍCIE do terreno próxima ao player...")
	print("  Player bottom: ", search_start)
	print("  Search end: ", search_end)
	
	# Configura raycast para encontrar terreno
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(search_start, search_end)
	
	# Só colide com terreno
	query.collision_mask = 8  # Layer do terreno
	query.exclude = [player]  # Exclui o próprio player
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		print("❌ Nenhum terreno encontrado próximo ao player")
		# Fallback: cria próximo aos pés do player
		return search_start + Vector2(0, 10)
	
	var terrain_surface = result.position
	print("✅ Superfície do terreno encontrada em: ", terrain_surface)
	print("  Distância do player: ", terrain_surface.distance_to(player.global_position))
	
	return terrain_surface

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

# ===== UTILITY METHODS =====

func get_explosion_stats() -> Dictionary:
	"""Retorna estatísticas da explosão para debug"""
	return {
		"explosion_radius": explosion_radius,
		"terrain_search_distance": terrain_search_distance
	}

@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id: int):
	"""Sincroniza colisão via network"""
	MessageBus.projectile_collision.emit(body_name, position, player_id)
	
	var projectile = get_parent()
	if projectile:
		projectile.queue_free()
