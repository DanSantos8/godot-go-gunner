class_name ProjectileFlyingState extends BattleState

var safety_timer: float = 0.0
var max_flight_time: float = 15.0

@rpc("authority", "call_local", "reliable")
func sync_projectile_flying_started():
	log_state("📡 RPC recebido: sync_projectile_flying_started")
	
	# Conecta collision handler (todos os clients precisam escutar)
	if not MessageBus.projectiles_pool_empty.is_connected(_on_projectiles_pool_empty):
		MessageBus.projectiles_pool_empty.connect(_on_projectiles_pool_empty)
	
@rpc("authority", "call_local", "reliable")
func sync_timeout_end_turn():
	state_machine.end_turn()

func enter():
	log_state("Projétil em voo - aguardando impacto...")
	if BattleManager.is_authority():
		battle_manager.log_network("Broadcasting projectile_flying_started...")
		sync_projectile_flying_started.rpc()
		safety_timer = max_flight_time
		
func execute(delta: float):
	if battle_manager.is_authority():
		safety_timer -= delta
		
		if safety_timer <= 0:
			log_state("⏰ Timeout de voo! Finalizando turno...")
			battle_manager.log_network("Broadcasting timeout_end_turn...")
			sync_timeout_end_turn.rpc()

func exit():
	if MessageBus.projectiles_pool_empty.is_connected(_on_projectiles_pool_empty):
		MessageBus.projectiles_pool_empty.disconnect(_on_projectiles_pool_empty)

func _on_projectiles_pool_empty():
	if battle_manager.is_authority():
		state_machine.explosion_occurred()
	else:
		log_state("Client detectou colisão (ignorando - aguardando authority)")
