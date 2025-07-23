extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if not BattleManager.is_authority():
		return
		
	var projectile = get_parent()
	var player_id = -1
	
	if body is Player:
		player_id = body.network_id		
		sync_projectile_collision.rpc("Player", global_position, player_id)
		sync_projectile_collision.rpc("Terrain", global_position, player_id)
		
	else:
		var entity_type = EntityHelper.get_entity_type(body)
		sync_projectile_collision.rpc(entity_type, global_position, player_id)

@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id: int):
	var explosion_data = _collect_explosion_data()
	MessageBus.projectile_collision.emit(body_name, position, player_id, explosion_data)
	
	var projectile = get_parent()
	if projectile:
		projectile.queue_free()

func _collect_explosion_data() -> Dictionary:
	# Pega explosion area do irmão
	var explosion_area = get_parent().get_node("ExplosionArea") as Area2D
	if not explosion_area:
		return {}
	
	var collision_shape = explosion_area.get_node("ExplosionCollision") as CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return {}
	
	var shape = collision_shape.shape
	return {
		"shape_type": shape.get_class(),
		"shape_data": _get_shape_data(shape)
	}

func _get_shape_data(shape: Shape2D) -> Dictionary:
	if shape is CircleShape2D:
		return {"radius": shape.radius}
	elif shape is RectangleShape2D:
		return {"size": shape.size}
	return {}
