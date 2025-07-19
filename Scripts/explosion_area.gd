extends Area2D

class_name ExplosionArea

func _on_body_entered(body: Node2D) -> void:
	var player_id = -1
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão...")
	
	if body is Player:
		player_id = body.network_id
	
	# TODO add shooter base damage
	sync_projectile_collision.rpc(EntityHelper.get_entity_type(body), global_position, player_id)
	
@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2, player_id):
	print("NETWORK ID: ", player_id)
	MessageBus.projectile_collision.emit(body_name, position, player_id)

	var projectile = get_parent()
	projectile.queue_free()
