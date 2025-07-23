extends RigidBody2D

@onready var sprite: AnimatedSprite2D = $ProjectileAnimation
@export var base_damage: float = 100.0
@export var spin_speed: float = 20 

func _ready() -> void:
	angular_velocity = spin_speed

func setup_shot(angle: float, power: float, facing_left: bool):
	var cos_value = cos(angle)
	var sin_value = sin(angle)
	var velocity_magnitude = power * 12
		
	if facing_left:
		cos_value = -cos_value

	var initial_velocity = Vector2(cos_value * velocity_magnitude, sin_value * velocity_magnitude)
	linear_velocity = initial_velocity
