extends Area2D	

class_name ExplosionArea

@export var destruction_data: DestructionData

func _ready():
	if not destruction_data:
		destruction_data = DestructionData.new()
		destruction_data.type = DestructionData.DestructionType.CIRCULAR
		destruction_data.radius = 15.0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Terrain":
		
		var terrain_container = get_tree().get_first_node_in_group("terrain_manager")
		
		if terrain_container:
			terrain_container.apply_destruction(global_position, destruction_data)
		else:
			print("TerrainContainer não encontrado!")
		
		queue_free()
