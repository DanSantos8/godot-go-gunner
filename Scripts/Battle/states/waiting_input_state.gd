class_name WaitingInputState extends BattleState

var turn_timer: float = 0.0
var max_turn_time: float = 30.0

func enter():
	log_state("Aguardando input do player " + str(battle_manager.current_player_index))
	
	# TOTAL LOCK SYSTEM
	var current_player = get_current_player()
	if current_player:
		battle_manager.unlock_player(current_player)
		log_state("Player desbloqueado: " + current_player.name)
	
	# Reset timer
	turn_timer = max_turn_time
	
	# Conecta evento de tiro
	if not MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.connect(_on_battle_event)

func execute(delta: float):
	# Monitora timeout do turno
	turn_timer -= delta
	
	if turn_timer <= 0:
		log_state("⏰ Timeout! Passando turno...")
		_end_turn_by_timeout()

func exit():
	log_state("Saindo do WaitingInput...")
	
	# Lock todos os players
	battle_manager.lock_all_players()
	
	# Desconecta eventos
	if MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.disconnect(_on_battle_event)

func _on_battle_event(event_type: String, data: Dictionary):
	if event_type == "projectile_launched":
		var shooter = data.get("player")
		var current_player = get_current_player()
		
		# VALIDAÇÃO DE SEGURANÇA
		if shooter == current_player:
			log_state("✅ Tiro válido de " + shooter.name)
			# Transição já acontece via battle_state_machine.projectile_launched()
		else:
			log_state("❌ Tiro inválido! Player " + shooter.name + " não é o atual")

func _end_turn_by_timeout():
	state_machine.end_turn()
