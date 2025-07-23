class_name WaitingTurnState extends State

func enter():	
	player.get_node("PlayerAnimation").play("Idle")
	player.velocity = Vector2.ZERO
	
func execute(delta: float):
	pass

func exit():
	player.restore_stamina_full()
