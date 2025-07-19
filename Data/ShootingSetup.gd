class_name ShootingSetup
extends RefCounted

# Dados do tiro
var angle: float
var position: Vector2
var power: float
var facing_left: bool
var shooter: Player

func _init(p_angle: float, p_position: Vector2, p_power: float, p_facing_left: bool, p_shooter: Player = null):
	angle = p_angle
	position = p_position
	power = p_power
	facing_left = p_facing_left
	shooter = p_shooter

# ===== VALIDATION METHODS =====

func is_valid() -> bool:
	"""Valida se o setup está correto"""
	if not shooter:
		print("❌ [SHOOTING_SETUP] Shooter não definido")
		return false
	
	if power <= 0 or power > 100:
		print("❌ [SHOOTING_SETUP] Power inválido: ", power)
		return false
	
	return true

func can_execute() -> bool:
	"""Verifica se o tiro pode ser executado (validações de gameplay)"""
	if not is_valid():
		return false
	
	# Verifica se é o turno do player
	if not BattleManager.can_player_act(shooter):
		print("❌ [SHOOTING_SETUP] ", shooter.name, " não pode atirar agora")
		return false
	
	# Verifica se player está vivo
	var health_component = shooter.get_node("HealthComponent")
	if health_component and not health_component.is_alive():
		print("❌ [SHOOTING_SETUP] ", shooter.name, " está morto")
		return false
	
	return true

# ===== HELPER METHODS =====

func get_shoot_velocity() -> Vector2:
	"""Calcula velocidade inicial do projétil"""
	var cos_value = cos(deg_to_rad(angle))
	var sin_value = sin(deg_to_rad(angle))
	var velocity_magnitude = power * 12
	
	if facing_left:
		cos_value = -cos_value
	
	return Vector2(cos_value * velocity_magnitude, sin_value * velocity_magnitude)

func get_shooter_index() -> int:
	"""Retorna índice do shooter no BattleManager"""
	return BattleManager.players.find(shooter)

func to_dict() -> Dictionary:
	"""Converte para Dictionary (útil para networking)"""
	return {
		"angle": angle,
		"position": var_to_str(position),
		"power": power,
		"facing_left": facing_left,
		"shooter_index": get_shooter_index(),
	}

static func from_dict(data: Dictionary) -> ShootingSetup:
	"""Cria ShootingSetup a partir de Dictionary"""
	var setup = ShootingSetup.new(
		data.angle,
		str_to_var(data.position),
		data.power,
		data.facing_left
	)
	
	# Encontra shooter pelo índice
	var shooter_index = data.get("shooter_index", -1)
	if shooter_index >= 0 and shooter_index < BattleManager.players.size():
		setup.shooter = BattleManager.players[shooter_index]
	
	return setup
