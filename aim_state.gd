class_name AimState extends State

@export var aim_speed = 30.0
@export var min_angle = -85.0
@export var max_angle = 45.0
@export var angle_accumulator = 0.0

func enter():
	# print("Aiming")
	player.player_flipped.connect(_on_character_flip)
	
func execute(delta):
	var aim_input = Input.get_axis("aim_down", "aim_up")
	if aim_input == 0:
		state_machine.change_state('idle')
	else: 
		angle_accumulator += (-aim_input) * aim_speed * delta

		if abs(angle_accumulator) >= 1.0:
			var angle_change = int(angle_accumulator)
			player.shooting_angle += angle_change
			player.shooting_angle = clamp(
				player.shooting_angle,
				min_angle,
				max_angle
			)
			angle_accumulator -= angle_change
			player.aim_ui.set_angle_label(player.shooting_angle)
	update_aim_visual()

func exit():
	pass

func update_aim_visual():
	if !player.animated_sprite.flip_h:
		player.weapon_pivot.rotation_degrees = player.shooting_angle
		player.weapon_pivot.scale.y = 1
		player.weapon_pivot.position.x = 8
	else:
		player.weapon_pivot.rotation_degrees = 180 - player.shooting_angle
		player.weapon_pivot.scale.y = -1
		player.weapon_pivot.position.x = -8

func _on_character_flip(direction):
	update_aim_visual()
