class_name ProjectileFlyingState extends BattleState

var safety_timer: float = 0.0
var max_flight_time: float = 15.0

func enter():
	log_state("Projétil em voo - aguardando impacto...")
	
	# LOCK TOTAL - nenhum player pode agir
	battle_manager.lock_all_players()
	
	# Reset timer de segurança
	safety_timer = max_flight_time

func execute(delta: float):
	# Timer de segurança - evita projétil "eterno"
	safety_timer -= delta
	
	if safety_timer <= 0:
		log_state("⏰ Timeout de voo! Finalizando turno...")
		state_machine.end_turn()

func exit():
	log_state("Saindo do ProjectileFlying...")
