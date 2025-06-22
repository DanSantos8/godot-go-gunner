extends CharacterBody2D
@onready var animated_sprite = $PlayerAnimation

@export var gravity: float = 10000.0
@export var speed: float = 150.00

@onready var weapon_pivot = $WeaponPivot
@onready var aim_line = $WeaponPivot/AimLine
@onready var power_bar = $PlayerUI/ProgressBar
@onready var aim_ui = $PlayerUI/AimUI
@onready var powerbar_label = $PlayerUI/PowerbarLabel
# Configurações de mira
@export var aim_speed = 30.0
@export var min_angle = -85.0
@export var max_angle = 45.0

@export var angle_accumulator = 0.0

var is_charging: bool = false
var current_power: float = 0.0
var max_power: float = 100.0
var charge_speed: float = 15

var shooting_angle = angle_accumulator
	
func _process(delta: float):
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _physics_process(delta: float) -> void:
	move(delta)
	aim(delta)
	charge_power(delta)
	update_aim_visual()
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
			aim_ui.set_angle_label(shooting_angle)
			

func update_aim_visual():
	if !animated_sprite.flip_h:
		weapon_pivot.rotation_degrees = shooting_angle
		weapon_pivot.scale.y = 1
		weapon_pivot.position.x = 8
	else:
		weapon_pivot.rotation_degrees = 180 - shooting_angle
		weapon_pivot.scale.y = -1
		weapon_pivot.position.x = -8

func charge_power(delta):
	if Input.is_action_pressed("charge"):
		if not is_charging:
			is_charging = true
			current_power = 0.0
		
		current_power += charge_speed * delta
		current_power = min(current_power, max_power)
		power_bar.value = min(current_power, max_power)
		powerbar_label.set_powerbar_value(current_power)

		
	elif Input.is_action_just_released("charge") and is_charging:
		shoot()
		is_charging = false
		current_power = 0.0
		power_bar.value = 0.0
		
func shoot():
	var facing_left: bool = animated_sprite.flip_h
	var shoot_offset: Vector2 = Vector2(-8, 0) if facing_left else Vector2(8, 0)
	var shoot_position: Vector2 = global_position + shoot_offset
	var angle: float = deg_to_rad(shooting_angle)
	
	ProjectileManager.create_projectile(shoot_position, angle, power_bar.value, facing_left)
	
	
