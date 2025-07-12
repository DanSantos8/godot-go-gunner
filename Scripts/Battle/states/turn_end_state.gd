class_name TurnEndState extends BattleState

# ===== NETWORK METHODS =====

@rpc("authority", "call_local", "reliable")
func sync_turn_ended(new_player_index: int):
	log_state("📡 RPC recebido: sync_turn_ended(" + str(new_player_index) + ")")
	
	# Validação básica
	if new_player_index < 0 or new_player_index >= battle_manager.players.size():
		log_state("❌ Índice de player inválido: " + str(new_player_index))
		return
	
	# Atualiza índice do player atual
	battle_manager.current_player_index = new_player_index
	
	# Emite evento para UI/logs
	MessageBus.emit_battle_event("turn_ended", {
		"previous_player_index": (new_player_index - 1) % battle_manager.players.size(),
		"new_player_index": new_player_index,
		"new_player": battle_manager.get_current_player()
	})
	
	# Transita para próximo turno
	state_machine.start_turn()

# ===== MAIN LOGIC =====

func enter():
	log_state("Finalizando turno do player " + str(battle_manager.current_player_index))
	
	# Garante que todos players estão bloqueados
	battle_manager.lock_all_players()
	
	# TODOS executam next_player(), mas só Authority broadcasts
	battle_manager.next_player()  # Remove o if!
	var new_player_index = battle_manager.current_player_index
	
	if battle_manager.is_authority():
		log_state("Authority: Próximo player será: " + str(new_player_index))
		battle_manager.log_network("Broadcasting turn_ended com próximo player: " + str(new_player_index))
		
		sync_turn_ended.rpc(new_player_index)
	else:
		# Client executa transição local imediata
		log_state("Client: Transição local para player: " + str(new_player_index))
		state_machine.start_turn()

func execute(delta: float):
	# TurnEndState é só transição instantânea
	# Não precisa de lógica contínua
	pass

func exit():
	log_state("Saindo do TurnEnd...")
