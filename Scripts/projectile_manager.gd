extends Node

var projectile_scene = preload("res://Scenes/projectile.tscn")
var current_projectile: RigidBody2D = null

func _ready() -> void:
	MessageBus.projectile_launched.connect(_on_battle_event)

func _on_battle_event(shooter: Player, shooting_setup: ShootingSetup):
	var angle = shooting_setup.angle
	var power = shooting_setup.power
	var position = shooting_setup.position
	var facing_left = shooter.animated_sprite.flip_h if shooter else false
	
	# Cria o projétil
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
	# Se não passou shooter, bloqueia por segurança
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
