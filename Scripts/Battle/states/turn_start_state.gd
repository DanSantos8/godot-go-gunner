class_name TurnStartState extends BattleState

func enter():
	log_state("Iniciando turno do player " + str(battle_manager.current_player_index))
	
	var current_player = get_current_player()
	if not current_player:
		log_state("❌ ERRO: Player atual não encontrado!")
		return
	
	_setup_player_states()
	_show_turn_feedback()
	
	# Pequena pausa para feedback visual
	await get_tree().create_timer(1.0).timeout
	
	# Transita para aguardar input do player
	log_state("Liberando controles para: " + current_player.name)
	state_machine.change_state("waitinginput")

func execute(delta: float):
	# TurnStartState é só transição, não precisa de lógica contínua
	pass

func exit():
	log_state("Saindo do TurnStart...")

# ===== PLAYER STATE MANAGEMENT =====

func _setup_player_states():
	"""Configura states de todos os players para o turno"""
	var current_player = get_current_player()
	
	for player in battle_manager.players:
		if player == current_player:
			_ensure_player_ready_for_turn(player)
		else:
			_set_player_waiting_turn(player)

func _ensure_player_ready_for_turn(player: Player):
	"""Garante que o player ativo está pronto para jogar"""
	if player.state_machine:
		var current_state_name = player.state_machine.current_state.get_script().get_global_name()
		if current_state_name == "WaitingTurnState":
			player.state_machine.change_state("idle")
		
		log_state("Player ativo preparado: " + player.name)

func _set_player_waiting_turn(player: Player):
	"""Coloca player em WaitingTurnState"""
	if player.state_machine:
		player.state_machine.change_state("waitingturn")
		log_state("Player em waiting: " + player.name)

# ===== LEGACY METHODS (mantidos para compatibilidade) =====

func _activate_current_player():
	"""Ativa o player atual e desativa os outros"""
	var current_player = get_current_player()
	
	for i in range(battle_manager.players.size()):
		var player = battle_manager.players[i]
		
		if i == battle_manager.current_player_index:
			# Player ativo
			_enable_player_controls(player)
			log_state("Player ativado: " + player.name)
		else:
			_disable_player_controls(player)

func _enable_player_controls(player: Player):
	"""Habilita os controles do player"""
	# Garante que o player pode receber inputs
	player.set_process_input(true)
	player.set_physics_process(true)
	
	# Se o player tiver uma propriedade para controlar isso
	if player.has_method("set_active"):
		player.set_active(true)

func _disable_player_controls(player: Player):
	"""Desabilita os controles do player"""
	# Impede que o player receba inputs
	player.set_process_input(false)
	
	# Mantém physics_process para gravidade/colisões
	# mas o player não deve responder a inputs
	if player.has_method("set_active"):
		player.set_active(false)

func _show_turn_feedback():
	"""Mostra feedback visual de qual player está jogando"""
	var current_player = get_current_player()
	
	# Emite evento para UI atualizar
	MessageBus.emit_battle_event("turn_started", {
		"player": current_player,
		"player_index": battle_manager.current_player_index,
		"player_name": current_player.name
	})
	
	log_state("🎯 Turno do " + current_player.name + " (Player " + str(battle_manager.current_player_index + 1) + ")")
