class_name IdleState extends State
func enter():
	print("Entrou no Idle")
	player.get_node("PlayerAnimation").play("Idle")
	player.velocity = Vector2.ZERO

func execute(delta: float):
	var input_direction = Input.get_axis("move_left", "move_right")
	var aim_input = Input.get_axis("aim_down", "aim_up")
	
	if input_direction != 0: 
		state_machine.change_state('move')
	elif aim_input != 0:
		state_machine.change_state('aim')
	elif Input.is_action_pressed('charge'):
		state_machine.change_state('charge')
	
func exit():
	print("Saindo do Idle")
