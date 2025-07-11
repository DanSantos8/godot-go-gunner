# Scripts/Battle/states/turn_start_state.gd - CÓDIGO COMPLETO AJUSTADO

class_name TurnStartState extends BattleState

# ===== NETWORK METHODS =====
@rpc("authority", "call_local", "reliable")
func sync_turn_started(player_index: int, turn_timer_value: float):
	log_state("📡 RPC recebido: sync_turn_started(" + str(player_index) + ", " + str(turn_timer_value) + ")")
	
	# Validação básica
	if player_index < 0 or player_index >= battle_manager.players.size():
		log_state("❌ Índice inválido recebido: " + str(player_index))
		return
	
	# Atualiza estado do BattleManager
	battle_manager.current_player_index = player_index
	battle_manager.turn_timer = turn_timer_value
	
	# Executa lógica comum
	_handle_turn_sync()
	
	log_state("✅ Estado sincronizado - Player atual: " + battle_manager.get_current_player().name)

# ===== MAIN LOGIC =====
func enter():
	log_state("Iniciando turno do player " + str(battle_manager.current_player_index))
	
	var current_player = get_current_player()
	if not current_player:
		log_state("❌ ERRO: Player atual não encontrado!")
		return
	
	# Executa lógica local
	_handle_turn_sync()
	
	# 🔥 NETWORK: Sincroniza com outros clients
	if battle_manager.is_authority():
		battle_manager.log_network("Broadcasting turn_started para clients...")
		sync_turn_started.rpc(battle_manager.current_player_index, battle_manager.max_turn_time)
	
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

# ===== RPC HANDLER =====
func _handle_turn_sync():
	"""Executa lógica comum para authority e clients"""
	_setup_player_states()
	_show_turn_feedback()

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

# ===== HELPER METHODS =====
# Métodos auxiliares podem ser adicionados aqui conforme necessário
