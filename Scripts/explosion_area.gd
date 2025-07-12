extends Area2D	

class_name ExplosionArea

@export var destruction_data: DestructionData
@export var base_damage: float = 25.0

# ===== NETWORK METHODS =====

@rpc("authority", "call_local", "reliable")
func sync_terrain_destruction(explosion_position: Vector2, destruction_radius: float):
	print("📡 RPC recebido: sync_terrain_destruction")
	
	var terrain_container = get_tree().get_first_node_in_group("terrain_manager")
	
	if terrain_container:
		terrain_container.apply_destruction(explosion_position, destruction_data)
		print("🌍 Terreno destruído em: ", explosion_position)
	else:
		print("❌ TerrainContainer não encontrado!")

@rpc("authority", "call_local", "reliable")
func sync_player_damage(player_name: String, damage_amount: float, explosion_position: Vector2):
	print("📡 RPC recebido: sync_player_damage(", player_name, ", ", damage_amount, ")")
	
	# Encontra o player pelo nome
	var target_player = _find_player_by_name(player_name)
	if not target_player:
		print("❌ Player não encontrado: ", player_name)
		return
	
	var health_component = target_player.get_node("HealthComponent")
	if health_component:
		health_component.take_damage(damage_amount)
		print("💥 ", player_name, " levou ", damage_amount, " de dano!")
		
		# Emite evento para logs/effects
		MessageBus.emit_battle_event("player_damage_applied", {
			"player": target_player,
			"damage": damage_amount,
			"position": explosion_position
		})
	else:
		print("❌ HealthComponent não encontrado em: ", player_name)

@rpc("authority", "call_local", "reliable")
func sync_projectile_cleanup():
	print("📡 RPC recebido: sync_projectile_cleanup")
	
	# Remove o projétil em todos os clients
	get_parent().queue_free()

# ===== MAIN LOGIC =====

func _ready():
	if not destruction_data:
		destruction_data = DestructionData.new()
		destruction_data.type = DestructionData.DestructionType.CIRCULAR
		destruction_data.radius = 15.0

func _on_body_entered(body: Node2D) -> void:
	print("💥 EXPLOSION AREA detectou: ", body.name, " | Tipo: ", body.get_class())
	
	# ⚠️ AUTHORITY ONLY: Processa efeitos e broadcasts
	if not BattleManager.is_authority():
		print("🔇 Cliente detectou colisão (ignorando - aguardando authority)")
		return
	
	print("👑 Authority processando colisão...")
	
	# Emite collision event (para ProjectileFlyingState)
	MessageBus.emit_projectile_collision(body.name, global_position, body)
	
	# Processa efeitos específicos
	if body.name == "Terrain":
		_handle_terrain_collision()
		
	elif body is Player:
		_handle_player_collision(body)
	
	else:
		print("🤷 Collision com objeto desconhecido: ", body.name)
		# Cleanup mesmo assim
		_cleanup_projectile()

# ===== COLLISION HANDLERS =====

func _handle_terrain_collision():
	print("🌍 Authority processando destruição de terreno...")
	
	# Broadcasts terrain destruction
	sync_terrain_destruction.rpc(global_position, destruction_data.radius)
	
	# Cleanup projectile
	_cleanup_projectile()

func _handle_player_collision(player: Player):
	print("🎯 Authority processando dano ao player: ", player.name)
	
	# Broadcasts player damage
	sync_player_damage.rpc(player.name, base_damage, global_position)
	
	# Cleanup projectile  
	_cleanup_projectile()

func _cleanup_projectile():
	print("🧹 Authority removendo projétil...")
	sync_projectile_cleanup.rpc()

# ===== HELPER METHODS =====

func _find_player_by_name(player_name: String) -> Player:
	"""Encontra player pelo nome nos clients"""
	for player in BattleManager.players:
		if player.name == player_name:
			return player
	return null
