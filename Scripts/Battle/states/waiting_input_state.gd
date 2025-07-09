class_name WaitingInputState extends BattleState

var turn_timer: float = BattleManager.turn_timer
var max_turn_time: float = BattleManager.max_turn_time

func enter():
	log_state("Aguardando input do player " + str(battle_manager.current_player_index))
	
	var current_player = get_current_player()
	if current_player:
		battle_manager.unlock_player(current_player)
		log_state("Player desbloqueado: " + current_player.name)
	
	turn_timer = max_turn_time
	
	if not MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.connect(_on_battle_event)

func execute(delta: float):
	turn_timer -= delta
	MessageBus.turn_timer.emit(turn_timer)
		
	if turn_timer <= 0:
		log_state("⏰ Timeout! Passando turno...")
		_end_turn_by_timeout()

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
