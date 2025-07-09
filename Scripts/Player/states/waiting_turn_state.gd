class_name WaitingTurnState extends State

func enter():
	print("🎮 [WAITING_TURN] ", player.name, " aguardando turno...")
	
	player.get_node("PlayerAnimation").play("Idle")
	player.velocity = Vector2.ZERO

func execute(delta: float):
	pass

func exit():
	print("🎮 [WAITING_TURN] ", player.name, " saindo do waiting turn...")
