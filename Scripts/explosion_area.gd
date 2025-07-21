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
	
	# Emite signal genérico - ProjectileManager decide o que fazer
	MessageBus.projectile_collision.emit("Terrain", impact_position, -1)
	
	# Remove projétil (sincronizado)
	var projectile = get_parent()
	if projectile:
		projectile.queue_free()

@rpc("authority", "call_local", "reliable")
func sync_player_collision(player_id: int, impact_position: Vector2, terrain_position: Vector2):
	"""Sincroniza colisão com player via network"""
	print("📡 Sincronizando colisão com player ID: ", player_id)
	
	# Emite signal genérico para player
	MessageBus.projectile_collision.emit("Player", impact_position, player_id)
	
	# Emite signal genérico para terreno (cratera direcional)
	MessageBus.projectile_collision.emit("Terrain", terrain_position, -1)
	
	# Remove projétil (sincronizado)
	var projectile = get_parent()
	if projectile:
		projectile.queue_free()

# ===== SISTEMA DE PENETRAÇÃO =====

func _find_terrain_through_player(player: Player) -> Vector2:
	"""Encontra terreno na direção de penetração do projétil"""
	
	var projectile = get_parent()
	if not projectile:
		print("❌ Projétil não encontrado")
		return Vector2.ZERO
	
	# Pega RayCast2D do projétil
	var raycast = projectile.get_node_or_null("RayCast2D")
	if not raycast:
		print("❌ RayCast2D não encontrado no projétil")
		return Vector2.ZERO
	
	# Configura RayCast para busca de penetração
	var penetration_direction = _get_penetration_direction()
	var ray_start = global_position  # Ponto de impacto
	var ray_distance = 50.0  # Máximo 50px
	
	# Configura direção e distância do ray
	raycast.target_position = penetration_direction * ray_distance
	raycast.enabled = true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit_position = raycast.get_collision_point()
		print("✅ RayCast encontrou terreno em: ", hit_position)
		return hit_position
	else:
		print("⚠️ RayCast não encontrou terreno em 50px")
		# Fallback: Posição estimada baseada na direção
		return ray_start + (penetration_direction * 30.0)

func _get_penetration_direction() -> Vector2:
	"""Calcula direção de penetração do projétil"""
	
	var projectile = get_parent()
	if not projectile:
		return Vector2.DOWN  # Fallback para baixo
	
	# Usa velocidade do projétil para determinar direção
	var velocity = projectile.linear_velocity
	if velocity.length() > 0:
		return velocity.normalized()
	else:
		return Vector2.DOWN  # Fallback para baixo

# ===== UTILITY METHODS =====

func get_explosion_stats() -> Dictionary:
	"""Retorna estatísticas da explosão para debug"""
	return {
		"explosion_radius": explosion_radius,
		"terrain_search_distance": terrain_search_distance
	}
