class_name ShootState extends State

# ===== NETWORK METHODS =====
@rpc("any_peer", "call_local", "reliable")
func sync_player_shot(shooter_index: int, angle: float, power: float, position: Vector2, facing_left: bool):
	print("📡 [SHOOT_STATE] RPC recebido: sync_player_shot(", shooter_index, ", ", angle, ", ", power, ")")
	
	# Validação básica
	if shooter_index < 0 or shooter_index >= BattleManager.players.size():
		print("❌ [SHOOT_STATE] Índice de player inválido: ", shooter_index)
		return
	
	var shooter = BattleManager.players[shooter_index]
	if not shooter:
		print("❌ [SHOOT_STATE] Player não encontrado: ", shooter_index)
		return
	
	# Cria projétil para todos
	_create_synchronized_projectile(shooter, angle, power, position, facing_left)
	
	# Emite evento para Battle FSM
	MessageBus.emit_battle_event("projectile_launched", {
		"player": shooter,
		"angle": angle,
		"power": power,
		"position": position
	})
	
	print("✅ [SHOOT_STATE] Tiro sincronizado para: ", shooter.name)

func _create_synchronized_projectile(shooter: Player, angle: float, power: float, position: Vector2, facing_left: bool):
	"""Cria projétil sincronizado em todos os clients"""
	ProjectileManager.create_projectile(position, deg_to_rad(angle), power, facing_left, shooter)

# ===== MAIN LOGIC =====
func enter():
	print("🔫 [SHOOT_STATE] ", player.name, " está atirando!")
	
	# Coleta dados do tiro
	var facing_left: bool = player.animated_sprite.flip_h
	var shoot_offset: Vector2 = Vector2(-20, 0) if facing_left else Vector2(20, 0)
	var shoot_position: Vector2 = player.global_position + shoot_offset
	var angle: float = player.shooting_angle
	var power: float = player.power_bar.value
	
	# Encontra índice do player no BattleManager
	var shooter_index = BattleManager.players.find(player)
	if shooter_index == -1:
		print("❌ [SHOOT_STATE] Player não encontrado no BattleManager!")
		return
	
	# 🔥 NETWORK: Sincroniza tiro com todos (qualquer player no seu turno)
	if BattleManager.can_player_act(player):
		BattleManager.log_network("Broadcasting player_shot de " + player.name)
		sync_player_shot.rpc(shooter_index, angle, power, shoot_position, facing_left)
	else:
		print("❌ [SHOOT_STATE] Player ", player.name, " não pode atirar agora!")
	
	# Transita para waiting turn
	state_machine.change_state('waitingturn')

func execute(delta):
	pass

func exit():
	pass
