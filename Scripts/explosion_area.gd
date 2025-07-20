extends Area2D
class_name ExplosionArea

func _ready():
	# Conecta ambos os signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	"""Detecta DamageZone (Area2D) do Player"""
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão com AREA...")
	print("[AREA DETECTADA]: ", area.name, " | Parent: ", area.get_parent().name)
	
	# Verifica se é DamageZone de um Player
	if area.get_parent() is Player:
		var player = area.get_parent() as Player
		var player_id = player.network_id
		
		print("🎯 Player detectado via DamageZone: ", player.name, " | ID: ", player_id)
		
		# Emite signal de dano ao player (MAS NÃO DESTRÓI PROJÉTIL)
		sync_projectile_collision.rpc("Player", global_position, player_id)

func _on_body_entered(body: Node2D) -> void:
	"""Detecta Terrain (StaticBody2D) e outros physics bodies"""
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão com BODY...")
	print("[BODY DETECTADO]: ", body.name)
	
	# Terrain ou outros objetos físicos
	var entity_type = EntityHelper.get_entity_type(body)
	sync_projectile_collision.rpc(entity_type, global_position, -1)

@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id: int):
	print("📡 RPC: ", body_name, " at ", position, " id: ", player_id)
	MessageBus.projectile_collision.emit(body_name, position, player_id)
	
	# Só destrói projétil quando atinge terrain (fim da trajetória)
	if body_name == "Terrain":
		var projectile = get_parent()
		if is_instance_valid(projectile):
			projectile.queue_free()
