# Scripts/Battle/states/projectile_flying_state.gd
class_name ProjectileFlyingState extends BattleState

var safety_timer: float = 0.0
var max_flight_time: float = 15.0  # 15 segundos máximo de voo

func enter():
	log_state("Projétil em voo - aguardando impacto...")
	
	# LOCK TOTAL - nenhum player pode agir
	battle_manager.lock_all_players()
	
	# Reset timer de segurança
	safety_timer = max_flight_time
	
	# Conecta evento de colisão do projétil
	if not MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.connect(_on_projectile_collision)
	
	# Emite evento para outros sistemas saberem que projétil está voando
	MessageBus.emit_battle_event("projectile_flying", {
		"current_player": get_current_player()
	})

func execute(delta: float):
	# Timer de segurança - evita projétil "eterno"
	safety_timer -= delta
	
	if safety_timer <= 0:
		log_state("⏰ Timeout de voo! Forçando explosão...")
		_force_explosion()

func exit():
	log_state("Saindo do ProjectileFlying...")
	
	# Desconecta eventos
	if MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.disconnect(_on_projectile_collision)

# ===== EVENT HANDLERS =====

func _on_projectile_collision(collision_type: String, position: Vector2, target: Node):
	log_state("💥 Colisão detectada - Tipo: " + collision_type + " | Posição: " + str(position))
	
	# Qualquer colisão causa transição para ExplosionState
	match collision_type:
		"terrain":
			log_state("Projétil atingiu terreno")
		"player":
			log_state("Projétil atingiu player: " + target.name)
		"boundary":
			log_state("Projétil saiu da tela")
		_:
			log_state("Tipo de colisão desconhecido: " + collision_type)
	
	# Transição para explosion independente do tipo
	_trigger_explosion(position, collision_type, target)

func _trigger_explosion(position: Vector2, collision_type: String, target: Node = null):
	"""Inicia a transição para ExplosionState"""
	
	MessageBus.emit_battle_event("explosion_triggered", {
		"position": position,
		"collision_type": collision_type,
		"target": target,
		"current_player": get_current_player()
	})
	
	state_machine.explosion_occurred()

func _force_explosion():
	"""Força explosão em caso de timeout"""
	var current_player = get_current_player()
	var fallback_position = current_player.global_position + Vector2(100, -50)
	
	_trigger_explosion(fallback_position, "timeout", null)
