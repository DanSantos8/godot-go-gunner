extends Area2D
class_name ExplosionArea

# Configurações de explosão
@export var explosion_radius: float = 30.0
@export var terrain_search_distance: float = 30.0

func _on_body_entered(body: Node2D) -> void:
	"""Detecta colisões e cria crateras no terreno"""
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão...")
	print("[BODY DETECTADO]: ", body.name, " (", body.get_class(), ")")
	
	var entity_type = EntityHelper.get_entity_type(body)
	
	if entity_type == "Player":
		print("🎯 Player atingido: ", body.name, " (ID: ", body.network_id, ")")
		
		# Sistema de penetração - encontra terreno "atrás" do player
		var terrain_hit_position = _find_terrain_through_player(body)
		
		if terrain_hit_position != Vector2.ZERO:
			print("🕳️ Terreno encontrado através do player em: ", terrain_hit_position)
			
			# Sincroniza colisão dupla: player + terreno direcional
			sync_player_collision.rpc(body.network_id, global_position, terrain_hit_position)
		else:
			print("❌ Terreno não encontrado através do player")
		
	elif entity_type == "Terrain":
		print("🌍 Terreno atingido diretamente em: ", global_position)
		
		# Colisão direta com terreno
		sync_terrain_collision.rpc(global_position)
		
	else:
		print("❓ Colisão com entidade desconhecida: ", entity_type)

@rpc("authority", "call_local", "reliable")
func sync_terrain_collision(impact_position: Vector2):
	"""Sincroniza criação de cratera via network"""
	print("📡 Sincronizando colisão em: ", impact_position)
	
	# Pega destruction_shape do projétil
	var projectile = get_parent()
	var destruction_shape = null
	if projectile and projectile.has_method("get") and projectile.get("destruction_shape"):
		destruction_shape = projectile.destruction_shape
	
	# Emite signal genérico com destruction_shape - ProjectileManager decide o que fazer
	MessageBus.projectile_collision.emit("Terrain", impact_position, -1, destruction_shape)
	
	# Remove projétil (sincronizado)
	if projectile:
		projectile.queue_free()

@rpc("authority", "call_local", "reliable")
func sync_player_collision(player_id: int, impact_position: Vector2, terrain_position: Vector2):
	"""Sincroniza colisão com player via network"""
	print("📡 Sincronizando colisão com player ID: ", player_id)
	
	# Pega destruction_shape do projétil
	var projectile = get_parent()
	var destruction_shape = null
	if projectile and projectile.has_method("get") and projectile.get("destruction_shape"):
		destruction_shape = projectile.destruction_shape
	
	# Emite signal genérico para player
	MessageBus.projectile_collision.emit("Player", impact_position, player_id, destruction_shape)
	
	# Emite signal genérico para terreno (cratera próxima ao player)
	MessageBus.projectile_collision.emit("Terrain", terrain_position, -1, destruction_shape)
	
	# Remove projétil (sincronizado)
	if projectile:
		projectile.queue_free()

# ===== SISTEMA DE PROXIMIDADE SIMPLES =====

func _find_terrain_through_player(player: Player) -> Vector2:
	"""Encontra terreno mais próximo da colisão (busca radial simples)"""
	
	var projectile = get_parent()
	if not projectile:
		print("❌ Projétil não encontrado")
		return Vector2.ZERO
	
	# Pega RayCast2D do projétil
	var raycast = projectile.get_node_or_null("RayCast2D")
	if not raycast:
		print("❌ RayCast2D não encontrado no projétil")
		return Vector2.ZERO
	
	# Ponto de colisão (onde explosão acontece)
	var collision_point = global_position
	
	# Busca radial em 8 direções ao redor da colisão
	var search_directions = [
		Vector2.DOWN,           # Baixo (prioritário)
		Vector2(0.7, 0.7),      # Sudeste
		Vector2(-0.7, 0.7),     # Sudoeste  
		Vector2.RIGHT,          # Direita
		Vector2.LEFT,           # Esquerda
		Vector2(0.7, -0.7),     # Nordeste
		Vector2(-0.7, -0.7),    # Noroeste
		Vector2.UP              # Cima (último recurso)
	]
	
	var search_distance = 30.0  # Distância bem curta para proximidade
	
	for direction in search_directions:
		var terrain_hit = _raycast_in_direction(raycast, collision_point, direction, search_distance)
		if terrain_hit != Vector2.ZERO:
			print("✅ Terreno próximo encontrado: ", terrain_hit, " (direção: ", direction, ")")
			return terrain_hit
	
	print("⚠️ Nenhum terreno próximo encontrado, usando posição embaixo do player")
	# Fallback: direto embaixo do player
	return player.global_position + Vector2(0, 20)

func _raycast_in_direction(raycast: RayCast2D, start_pos: Vector2, direction: Vector2, distance: float) -> Vector2:
	"""Faz raycast em uma direção específica a partir do ponto de colisão"""
	
	# Posiciona raycast no ponto de colisão (não no player)
	raycast.global_position = start_pos
	raycast.target_position = direction * distance
	raycast.enabled = true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return Vector2.ZERO

# ===== UTILITY METHODS =====

func get_explosion_stats() -> Dictionary:
	"""Retorna estatísticas da explosão para debug"""
	return {
		"explosion_radius": explosion_radius,
		"terrain_search_distance": terrain_search_distance
	}
