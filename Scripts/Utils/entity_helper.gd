class_name EntityHelper

static func get_entity_type(body: Node2D) -> String:
	if body.is_in_group("players"):
		return "Player"
	elif body.is_in_group("npcs"):
		return "NPC"
	elif body.name == "Terrain":
		return "Terrain"
	elif body.is_in_group('terrain'):
		return "Terrain"
	else:
		return "Unknown"
