# Scripts/message_bus.gd - UPDATED
extends Node

# ===== SIGNALS =====
signal battle_event(event_type: String, data: Dictionary)
signal projectile_launched(shooter: Player, shooting_setup: ShootingSetup)
# Signal específico para colisão de projétil
signal projectile_collision(collision_type: String, position: Vector2, target: Node)

signal turn_timer(seconds: int)
signal game_over(winner: Player)

# ===== EMIT METHODS =====
func emit_battle_event(event_type: String, data: Dictionary):
	battle_event.emit(event_type, data)
	_log_event(event_type, data)

# Método específico para colisão de projétil
func emit_projectile_collision(collision_type: String, position: Vector2, target: Node = null):
	projectile_collision.emit(collision_type, position, target)
	_log_event("projectile_collision", {
		"type": collision_type,
		"position": position,
		"target": target.name if target else "none"
	})

# ===== LOGGING =====
func _log_event(event_type: String, data: Dictionary):
	# Filtro de logs por tipo (para não poluir console)
	var important_events = [
		"battle_started", "battle_ended", "player_shot", 
		"projectile_hit", "player_died", "projectile_collision",
		"explosion_triggered", "projectile_flying"
	]
	
	if event_type in important_events:
		print("🎮 [MESSAGE_BUS] ", event_type, " | ", data)
	elif OS.is_debug_build():
		print("🔷 [MESSAGE_BUS] ", event_type, " | ", data)

# ===== DEBUG METHODS =====
func get_connected_signals() -> Dictionary:
	var connections = {}
	var signal_list = get_signal_list()
	
	for signal_info in signal_list:
		var signal_name = signal_info.name
		connections[signal_name] = get_signal_connection_list(signal_name).size()
	
	return connections

func debug_connections():
	print("📡 [MESSAGE_BUS] Signal Connections:")
	var connections = get_connected_signals()
	for signal_name in connections:
		print("  ", signal_name, ": ", connections[signal_name], " listeners")
