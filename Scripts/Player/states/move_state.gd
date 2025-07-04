class_name MoveState extends State

@export var gravity: float = 10000.0
@export var speed: float = 150.00

func enter():
	player.get_node("PlayerAnimation").play("Walking")
	
func execute(delta: float):
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
	
	if input_direction == 0: 
		state_machine.change_state('idle')
		player.velocity.x = move_toward(player.velocity.x, 0, speed * delta * 8)
	else: 
		player.velocity.x = input_direction * speed
		player.move_and_slide()
		player.player_flipped.emit(input_direction)

func exit():
	# print("Saindo do Move")
	pass
