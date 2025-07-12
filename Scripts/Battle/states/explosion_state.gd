class_name ExplosionState extends BattleState

var explosion_timer: float = 0.0
var explosion_duration: float = 2.0

# ===== NETWORK METHODS =====

@rpc("authority", "call_local", "reliable")
func sync_explosion_finished():
	log_state("📡 RPC recebido: sync_explosion_finished")
	
	# Transita para TurnEnd em todos os clients
	state_machine.end_turn()

# ===== MAIN LOGIC =====

func enter():
	log_state("💥 Explosão em andamento...")
	
	# Lock players (redundante, mas garante)
	battle_manager.lock_all_players()
	
	# TODOS iniciam timer local (authority controlará via RPC)
	explosion_timer = explosion_duration
	
	if battle_manager.is_authority():
		battle_manager.log_network("Authority iniciando controle de explosão: " + str(explosion_duration) + "s")
	
	# TODO: Futuros efeitos visuais
	_start_visual_effects()

func execute(delta: float):
	# ⚠️ AUTHORITY ONLY: Controla quando acabar
	if battle_manager.is_authority():
		explosion_timer -= delta
		
		if explosion_timer <= 0:
			log_state("Authority: Explosão finalizada - passando turno...")
			battle_manager.log_network("Broadcasting explosion_finished...")
			sync_explosion_finished.rpc()
	
	# CLIENT: apenas roda efeitos visuais locais
	# (timer vem via RPC do authority)

func exit():
	log_state("Saindo do Explosion...")
	
	# Cleanup de efeitos visuais
	_cleanup_visual_effects()

# ===== VISUAL EFFECTS (LOCAL) =====

func _start_visual_effects():
	"""Inicia efeitos visuais locais (sem sync)"""
	log_state("🎆 Iniciando efeitos visuais da explosão...")
	
	# TODO: Implementar futuramente
	# - Particle effects
	# - Screen shake  
	# - Sound effects
	# - Slow motion
	# - Camera effects

func _cleanup_visual_effects():
	"""Limpa efeitos visuais locais"""
	log_state("🧹 Limpando efeitos visuais...")
	
	# TODO: Cleanup quando implementar efeitos
	pass
