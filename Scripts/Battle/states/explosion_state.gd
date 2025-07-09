class_name ExplosionState extends BattleState

var explosion_timer: float = 0.0
var explosion_duration: float = 2.0

func enter():
	log_state("💥 Explosão em andamento...")
	battle_manager.lock_all_players()
	
	# Reset timer
	explosion_timer = explosion_duration
	
	# Conecta eventos relevantes se necessário
	if not MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.connect(_on_battle_event)
	
	# Processa efeitos da explosão
	_finish_explosion()
	
func execute(delta: float):
	# Aguarda efeitos visuais terminarem
	explosion_timer -= delta
	
	if explosion_timer <= 0:
		log_state("Explosão finalizada - passando turno...")
		state_machine.end_turn()

func exit():
	log_state("Saindo do Explosion...")
	
	# Desconecta eventos
	if MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.disconnect(_on_battle_event)

# ===== EXPLOSION PROCESSING =====

func _finish_explosion():
	await get_tree().create_timer(1.0).timeout
	state_machine.end_turn()

# ===== EVENT HANDLERS =====

func _on_battle_event(event_type: String, data: Dictionary):
	# Escuta eventos durante a explosão se necessário
	match event_type:
		"terrain_destruction_complete":
			log_state("Destruição de terreno finalizada")
		"player_damage_applied":
			log_state("Dano aplicado ao player")
		_:
			pass
