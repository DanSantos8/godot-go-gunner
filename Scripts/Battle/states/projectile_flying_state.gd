class_name ProjectileFlyingState extends BattleState

var safety_timer: float = 0.0
var max_flight_time: float = 15.0

# ===== NETWORK METHODS =====

@rpc("authority", "call_local", "reliable")
func sync_projectile_flying_started():
	log_state("📡 RPC recebido: sync_projectile_flying_started")
	
	# Conecta collision handler (todos os clients precisam escutar)
	if not MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.connect(_on_projectile_collision)
	
	log_state("✅ Todos players bloqueados - projétil em voo")

@rpc("authority", "call_local", "reliable")
func sync_timeout_end_turn():
	log_state("📡 RPC recebido: sync_timeout_end_turn")
	# Timeout - força fim do turno
	state_machine.end_turn()

# ===== MAIN LOGIC =====

func enter():
	log_state("Projétil em voo - aguardando impacto...")
	
	battle_manager.log_network("Broadcasting projectile_flying_started...")
	sync_projectile_flying_started.rpc()
	
	# AUTHORITY: inicia timer de segurança
	safety_timer = max_flight_time

func execute(delta: float):
	if battle_manager.is_authority():
		safety_timer -= delta
		
		if safety_timer <= 0:
			log_state("⏰ Timeout de voo! Finalizando turno...")
			battle_manager.log_network("Broadcasting timeout_end_turn...")
			sync_timeout_end_turn.rpc()

func exit():
	log_state("Saindo do ProjectileFlying...")
	
	# Desconecta collision handler
	if MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.disconnect(_on_projectile_collision)

# ===== EVENT HANDLERS =====

func _on_projectile_collision(collision_type: String, position: Vector2, target: Node):
	# ⚠️ AUTHORITY ONLY: Decide quando explodir
	if battle_manager.is_authority():
		log_state("Authority detectou colisão: " + collision_type)
		battle_manager.log_network("Broadcasting explosion_occurred...")
		state_machine.explosion_occurred()
	else:
		log_state("Client detectou colisão (ignorando - aguardando authority)")
