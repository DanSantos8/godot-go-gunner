class_name ShootState extends State

func enter():
	# print("Shooting!")
	pass
	
func execute(delta):
	var facing_left: bool = player.animated_sprite.flip_h
	var shoot_offset: Vector2 = Vector2(-8, 0) if facing_left else Vector2(8, 0)
	var shoot_position: Vector2 = player.global_position + shoot_offset
	var angle: float = deg_to_rad(player.shooting_angle)
	ProjectileManager.create_projectile(shoot_position, angle, player.power_bar.value, facing_left)
	
	state_machine.change_state('idle')

func exit():
	pass
