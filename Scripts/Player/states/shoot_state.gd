class_name ShootState extends State

func enter():
	# print("Shooting!")
	pass
	
func execute(delta):
	var facing_left: bool = player.animated_sprite.flip_h
	var shoot_offset: Vector2 = Vector2(-20, 0) if facing_left else Vector2(20, 0)
	var shoot_position: Vector2 = player.global_position + shoot_offset
	var angle: float = deg_to_rad(player.shooting_angle)
	ProjectileManager.create_projectile(shoot_position, angle, player.power_bar.value, facing_left, player)
	
	MessageBus.emit_battle_event("projectile_launched", {
		"player": player,
		"angle": player.shooting_angle,
		"power": player.power_bar.value,
		"position": shoot_position
	})
	
	state_machine.change_state('waitingturn')

func exit():
	pass
