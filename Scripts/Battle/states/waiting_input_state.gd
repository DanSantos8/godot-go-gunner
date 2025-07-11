class_name WaitingInputState extends BattleState

var turn_timer: float = BattleManager.turn_timer
var max_turn_time: float = BattleManager.max_turn_time

# ===== TIMER SYNC =====
var timer_sync_interval: float = 1.0  # Sincroniza a cada 1 segundo
var timer_sync_accumulator: float = 0.0

@rpc("authority", "call_local", "reliable")
func sync_timer_update(remaining_time: float):
	log_state("📡 RPC Timer: " + str(remaining_time) + "s restantes")
	
	# Atualiza timer local
	turn_timer = remaining_time
	MessageBus.turn_timer.emit(turn_timer)
	
	
func enter():
	log_state("Aguardando input do player " + str(battle_manager.current_player_index))
	
	var current_player = get_current_player()
	if current_player:
		battle_manager.unlock_player(current_player)
		log_state("Player desbloqueado: " + current_player.name)
	
	# AUTHORITY: inicia timer
	if battle_manager.is_authority():
		turn_timer = max_turn_time
		timer_sync_accumulator = timer_sync_interval
		# Envia timer inicial imediatamente
		sync_timer_update.rpc(turn_timer)
	
	if not MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.connect(_on_battle_event)

func execute(delta: float):
	if battle_manager.is_authority():
		# AUTHORITY: controla timer real
		turn_timer -= delta
		MessageBus.turn_timer.emit(turn_timer)
		
		# Sincroniza a cada 1 segundo
		timer_sync_accumulator += delta
		if timer_sync_accumulator >= timer_sync_interval:
			battle_manager.log_network("Broadcasting timer: " + str(turn_timer))
			sync_timer_update.rpc(turn_timer)
			timer_sync_accumulator = 0.0
		
		# Timeout
		if turn_timer <= 0:
			log_state("⏰ Timeout! Passando turno...")
			_end_turn_by_timeout()
	
	# CLIENT: apenas aguarda RPC do timer
	# (não faz nada, timer vem via RPC)

func exit():
	log_state("Saindo do WaitingInput...")
	
	battle_manager.lock_all_players()
	
	if MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.disconnect(_on_battle_event)

func _on_battle_event(event_type: String, data: Dictionary):
	if event_type == "projectile_launched":
		var shooter = data.get("player")
		var current_player = get_current_player()
		
		if shooter == current_player:
			log_state("✅ Tiro válido de " + shooter.name)
			state_machine.projectile_launched()
		else:
			log_state("❌ Tiro inválido! Player " + shooter.name + " não é o atual")

func _end_turn_by_timeout():
	state_machine.end_turn()
