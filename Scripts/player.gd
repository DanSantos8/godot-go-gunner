extends CharacterBody2D
@onready var animated_sprite = $PlayerAnimation

@export var gravity: float = 10000.0
@export var speed: float = 150.00

@onready var weapon_pivot = $WeaponPivot
@onready var aim_line = $WeaponPivot/AimLine
@onready var power_bar = $PlayerUI/ProgressBar

# Configurações de mira
@export var aim_speed = 30.0
@export var min_angle = -85.0
@export var max_angle = 45.0

@export var angle_accumulator = 0.0

var shooting_angle = angle_accumulator
	
func _process(delta: float):
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _physics_process(delta: float) -> void:
	move(delta)
	aim(delta)
	animate()
	
func move(delta: float):
	# Aplica gravidade quando não está no chão
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if input_direction != 0:
		velocity.x = input_direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 8)
	
	move_and_slide()

func animate():
	if abs(velocity.x) > 10:
		animated_sprite.play('Walking')
	else: 
		animated_sprite.play('Idle')
	
func aim(delta):
	var aim_input = Input.get_axis("aim_down", "aim_up")
	if aim_input != 0:
		angle_accumulator += (-aim_input) * aim_speed * delta

		if abs(angle_accumulator) >= 1.0:
			var angle_change = int(angle_accumulator)
			shooting_angle += angle_change
			shooting_angle = clamp(
				shooting_angle,
				min_angle,
				max_angle
			)
			angle_accumulator -= angle_change
			update_aim_visual()

func update_aim_visual():
	if animated_sprite.flip_h:
		weapon_pivot.rotation_degrees = shooting_angle
		weapon_pivot.scale.y = 1
	else:
		weapon_pivot.rotation_degrees = 180 - shooting_angle
		weapon_pivot.scale.y = -1
