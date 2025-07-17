extends Area2D

class_name ExplosionArea

func _on_body_entered(body: Node2D) -> void:
	if not BattleManager.is_authority():
		return
	
	print("👑 Authority processando colisão...")
	
	# TODO add shooter base damage
	_sync_projectile_collision.rpc(body.name, global_position)
	
@rpc("authority", "call_local", "reliable")
func _sync_projectile_collision(body: String, position: Vector2):
	MessageBus.projectile_collision.emit(body, position)
