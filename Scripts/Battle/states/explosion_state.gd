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
	_process_explosion_effects()

func execute(delta: float):
	# Aguarda efeitos visuais terminarem
	explosion_timer -= delta
	
	if explosion_timer <= 0:
		log_state("Explosão finalizada - passando turno...")
		_finish_explosion()

func exit():
	log_state("Saindo do Explosion...")
	
	# Desconecta eventos
	if MessageBus.battle_event.is_connected(_on_battle_event):
		MessageBus.battle_event.disconnect(_on_battle_event)

# ===== EXPLOSION PROCESSING =====

func _process_explosion_effects():
	"""Processa todos os efeitos da explosão"""
	log_state("Processando efeitos da explosão...")
	
	# Por enquanto, só aguarda o timer
	# TODO: Adicionar partículas, screen shake, etc.
	
	# Emite evento para outros sistemas saberem que explosão começou
	MessageBus.emit_battle_event("explosion_started", {
		"current_player": get_current_player()
	})
	_finish_explosion()

func _finish_explosion():
	"""Finaliza a explosão e passa o turno"""
	
	# Emite evento de explosão finalizada
	MessageBus.emit_battle_event("explosion_finished", {
		"current_player": get_current_player()
	})
	
	# Transição para fim de turno
	state_machine.end_turn()

# ===== EVENT HANDLERS =====

func _on_battle_event(event_type: String, data: Dictionary):
	# Escuta eventos durante a explosão se necessário
	print("ENTROU???")
	match event_type:
		"terrain_destruction_complete":
			log_state("Destruição de terreno finalizada")
		"player_damage_applied":
			log_state("Dano aplicado ao player")
		_:
			pass
