extends Node

var projectile_scene = preload("res://Scenes/projectile.tscn")
var current_projectile: RigidBody2D = null
var powerup_queue: Array = []

func _ready() -> void:
	MessageBus.projectile_launched.connect(_execute_powered_shot)
	MessageBus.powerup_selected.connect(_add_shooting_powerup)
	MessageBus.projectile_collision.connect(_on_projectile_collision)

func _execute_powered_shot(shooter: Player, shooting_setup: ShootingSetup):
	var angle = shooting_setup.angle
	var power = shooting_setup.power
	var position = shooting_setup.position
	var facing_left = shooter.animated_sprite.flip_h if shooter else false
	
	var total_projectiles = _calculate_total_projectiles()
	print("[DEBUG] Total projectiles: ", total_projectiles)
	for i in range(total_projectiles):
		current_projectile = create_projectile(position, deg_to_rad(angle), power, facing_left, shooter)

func create_projectile(position: Vector2, angle: float, power: float, facing_left: bool, shooter: Player = null):
	# 🛡️ VALIDAÇÃO DE SEGURANÇA
	if not _can_player_shoot(shooter):
		print("❌ [PROJECTILE_MANAGER] Tiro bloqueado - player não autorizado!")
		return null
	
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = position
	projectile.setup_shot(angle, power, facing_left)
	
	print("🚀 [PROJECTILE_MANAGER] Projétil criado por: ", shooter.name if shooter else "unknown")
	current_projectile = projectile
	return projectile

func _can_player_shoot(shooter: Player) -> bool:
	if not shooter:
		print("❌ [PROJECTILE_MANAGER] Shooter não informado!")
		return false
	
	# Verifica se é o player atual do turno
	if not BattleManager.can_player_act(shooter):
		print("❌ [PROJECTILE_MANAGER] ", shooter.name, " não pode atirar agora!")
		return false
	
	# Verifica se player está vivo           
	var health_component = shooter.get_node("HealthComponent")
	if health_component and not health_component.is_alive():
		print("❌ [PROJECTILE_MANAGER] ", shooter.name, " está morto!")
		return false
	
	return true

func _add_shooting_powerup(data: PowerupResource):
	print("[ENTROU]", powerup_queue.size())
	powerup_queue.append(data)

func _clear_shooting_powerup():
	powerup_queue = []
	
func _calculate_total_projectiles() -> int:
	var total = 1
	if powerup_queue.size() == 0:
		return total
		
	for powerup in powerup_queue:
		total += powerup.additional_projectiles
	return total

func _apply_damage_modifiers(base_power: float) -> float:
	return 25.0
	
func _on_projectile_collision(body: String, position: Vector2):
	if not body: 
		print("[Projectile Manager]: Body not indentified")
	
	match body:
		"Player": MessageBus.projectile_collided_with_player.emit(25.0)
		"Terrain": MessageBus.projectile_collided_with_terrain.emit(position)
		_: MessageBus.projectile_destroyed.emit()
