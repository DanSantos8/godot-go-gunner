extends Area2D

class_name ExplosionArea

func _on_body_entered(body: Node2D) -> void:
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão...")
	
	# TODO add shooter base damage
	sync_projectile_collision.rpc(EntityHelper.get_entity_type(body), global_position)
	
@rpc("authority", "call_local", "reliable")
func sync_projectile_collision(body_name: String, position: Vector2):
	MessageBus.projectile_collision.emit(body_name, position)

	var projectile = get_parent()
	projectile.queue_free()
