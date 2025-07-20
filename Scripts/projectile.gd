extends RigidBody2D

@onready var sprite: AnimatedSprite2D = $ProjectileAnimation
@onready var explosion_area: ExplosionArea = $ExplosionArea

# Configs
@export var explosion_radius: float = 50.0
@export var base_damage: float = 100.0
@export var spin_speed: float = 20 
@export var rotation_speed: float = 5.0

# Controle de colisão
var has_collided: bool = false
signal projectile_destroyed

func _ready() -> void:
	angular_velocity = spin_speed
	MessageBus.projectile_destroyed.connect(_destroy_projectile)
	
	# Monitor para sair da tela
	_setup_boundary_detection()

func setup_shot(angle: float, power: float, facing_left: bool):
	var cos_value = cos(angle)
	var sin_value = sin(angle)
	var velocity_magnitude = power * 12
		
	if facing_left:
		cos_value = -cos_value

	var initial_velocity = Vector2(cos_value * velocity_magnitude, sin_value * velocity_magnitude)
	linear_velocity = initial_velocity
	

func _setup_boundary_detection():
	# Usa VisibleOnScreenNotifier2D para detectar saída da tela
	var notifier = VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
	if has_collided:
		return
	
	print("🎯 [PROJECTILE] Saiu da tela")
	has_collided = true
	
	# Emite signal de boundary
	# MessageBus.emit_projectile_collision("boundary", global_position, null)
	
	# _destroy_projectile()

# ===== DESTRUCTION =====

func _destroy_projectile():
	queue_free()
