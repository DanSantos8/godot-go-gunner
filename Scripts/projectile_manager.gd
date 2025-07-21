extends Node

var projectile_scene = preload("res://Scenes/projectile.tscn")
var current_projectile: RigidBody2D = null

# powerups - buffs
var powerup_queue: Array = []
var pool_size: int = 0
# TODO refactor to work as burst_projectiles
var trident_projectiles: bool = false
var projectile_base_damage: int = 0

func _ready() -> void:
	MessageBus.projectile_launched.connect(_execute_powered_shot)
	MessageBus.powerup_selected.connect(_add_shooting_powerup)
	MessageBus.projectile_collision.connect(_on_projectile_collision)
	MessageBus.end_turn.connect(_clear_shooting_powerup)

func _execute_powered_shot(shooter: Player, shooting_setup: ShootingSetup):
	var angle = shooting_setup.angle
	var power = shooting_setup.power
	var position = shooting_setup.position
	var facing_left = shooter.animated_sprite.flip_h if shooter else false
	
	projectile_base_damage = _calculate_base_damage(shooter.player_stats.base_damage)
	var additional_projectiles = _calculate_additional_projectiles()
	pool_size = additional_projectiles * 3 if trident_projectiles else additional_projectiles
	
	for projectile in range(additional_projectiles):
		current_projectile = create_projectile(position, deg_to_rad(angle), power, facing_left, shooter)
		await get_tree().create_timer(1).timeout

func create_projectile(position: Vector2, angle: float, power: float, facing_left: bool, shooter: Player = null):
	var projectiles = []
	var angle_spread = deg_to_rad(5)
	var angles = [angle - angle_spread, angle, angle + angle_spread]
	var powers = [power + 1.5, power, power - 1]
	
	if trident_projectiles:
		for i in range(3):
			var projectile = projectile_scene.instantiate()
			get_tree().current_scene.add_child(projectile)
			
			projectile.global_position = position
			projectile.setup_shot(angles[i], powers[i], facing_left)
			projectiles.append(projectile)
		# TODO refactor for camera porposes
		current_projectile = projectiles[0]
		return current_projectile
	
	# single shot
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = position
	projectile.setup_shot(angle, power, facing_left)
	projectiles.append(projectile)
	current_projectile = projectile
	return current_projectile
		
func _add_shooting_powerup(data: PowerupResource):
	if data.powerup_id == 'pup3':
		trident_projectiles = true
	else:
		powerup_queue.append(data)
		
func _clear_shooting_powerup():
	powerup_queue = []
	trident_projectiles = false
	pool_size = 0
	
func _calculate_additional_projectiles() -> int:
	var total = 1
	if powerup_queue.size() == 0:
		return total
		
	for powerup in powerup_queue:
		total += powerup.additional_projectiles
	return total

func _calculate_base_damage(player_base_damage) -> float:
	var accumulator_multiplier_damage: float = 0
	
	if powerup_queue.size() == 0:
		return player_base_damage
	
	for powerup in powerup_queue:
		accumulator_multiplier_damage += powerup.damage_multiplier
	
	return player_base_damage * accumulator_multiplier_damage / powerup_queue.size()
	
func _apply_damage_modifiers(base_power: float) -> float:
	return 25.0
	
func _on_projectile_collision(body: String, position: Vector2, target_id: int, destruction_shape: DestructionShape = null):
	if not body:
		print("[Projectile Manager]: Body not indentified")
	
	match body:
		"Player": 
			MessageBus.projectile_collided_with_player.emit(target_id, projectile_base_damage)
		"Terrain": 
			# Passa DestructionShape para o terreno
			MessageBus.projectile_collided_with_terrain.emit(position, destruction_shape)
		_: 
			MessageBus.projectile_destroyed.emit()
	
	pool_size = pool_size - 1
	
	if pool_size == 0:
		MessageBus.projectiles_pool_empty.emit()
	
