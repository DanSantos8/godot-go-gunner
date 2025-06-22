extends Node

var projectile_scene = preload("res://Scenes/projectile.tscn")

func create_projectile(position: Vector2, angle: float, power: float, facing_left: bool):
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = position
	projectile.setup_shot(angle, power, facing_left)
	
