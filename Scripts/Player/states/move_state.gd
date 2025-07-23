class_name MoveState extends State

@export var speed: float = 20.00

var previous_position: Vector2
var stamina_per_distance: float = 5.0

func enter():
	if not player.has_stamina(1):
		state_machine.change_state('idle')
		return
	
	player.get_node("PlayerAnimation").play("Walking")
	
	previous_position = player.global_position	
func execute(delta: float):
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if not player.has_stamina(1) and input_direction != 0:
		state_machine.change_state('idle')
		return
	
	if input_direction == 0: 
		state_machine.change_state('idle')
		player.velocity.x = move_toward(player.velocity.x, 0, speed * delta * 8)
	else: 
		player.velocity.x = input_direction * speed
		player.move_and_slide()
		player.player_flipped.emit(input_direction)
		
		_track_distance_and_consume_stamina()

func exit():
	pass

func _track_distance_and_consume_stamina():	
	var current_position = player.global_position
	var distance_moved = previous_position.distance_to(current_position)
	
	# Acumula distância (persiste entre entradas no state)
	player.distance_accumulator += distance_moved
	
	# Se acumulou distância suficiente, consome stamina
	if player.distance_accumulator >= stamina_per_distance:
		var stamina_to_consume = int(player.distance_accumulator / stamina_per_distance)
		
		if player.consume_stamina(stamina_to_consume):
			player.distance_accumulator -= stamina_to_consume * stamina_per_distance
			print("🔋 [MOVE_STATE] Consumiu ", stamina_to_consume, " stamina por movimento")
		else:
			# Sem stamina, para movimento
			print("🚫 [MOVE_STATE] Sem stamina para continuar!")
			state_machine.change_state('idle')
			return
	previous_position = current_position
