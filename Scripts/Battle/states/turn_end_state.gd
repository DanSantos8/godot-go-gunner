class_name TurnEndState extends BattleState

# ===== NETWORK METHODS =====

@rpc("authority", "call_local", "reliable")
func sync_turn_ended(new_player_index: int):	
	if new_player_index < 0 or new_player_index >= battle_manager.players.size():
		log_state("❌ Índice de player inválido: " + str(new_player_index))
		return
	
	# Atualiza índice do player atual
	battle_manager.current_player_index = new_player_index
	
	MessageBus.end_turn.emit()
	state_machine.start_turn()

# ===== MAIN LOGIC =====

func enter():
	log_state("Finalizando turno do player " + str(battle_manager.current_player_index))
	
	# TODOS executam next_player(), mas só Authority broadcasts
	battle_manager.next_player()
	var new_player_index = battle_manager.current_player_index
	
	if battle_manager.is_authority():
		log_state("Authority: Próximo player será: " + str(new_player_index))
		battle_manager.log_network("Broadcasting turn_ended com próximo player: " + str(new_player_index))
		
		sync_turn_ended.rpc(new_player_index)
	else:
		log_state("Client: Transição local para player: " + str(new_player_index))
		state_machine.start_turn()

func execute(delta: float):
	# TurnEndState é só transição instantânea
	# Não precisa de lógica contínua
	pass

func exit():
	log_state("Saindo do TurnEnd...")
