class_name ShootState extends State

# ===== NETWORK METHODS =====
@rpc("any_peer", "call_local", "reliable")
func sync_player_shot(shooter_index: int, setup_data: Dictionary):	
	# Validação básica
	if shooter_index < 0 or shooter_index >= BattleManager.players.size():
		print("❌ [SHOOT_STATE] Índice de player inválido: ", shooter_index)
		return
	
	var shooter = BattleManager.players[shooter_index]
	if not shooter:
		print("❌ [SHOOT_STATE] Player não encontrado: ", shooter_index)
		return
	
	var shooting_setup = ShootingSetup.from_dict(setup_data)
	# Emite evento para Battle FSM
	MessageBus.projectile_launched.emit(shooter, shooting_setup)
	MessageBus.emit_battle_event("projectile_launched", {
		"player": shooter,
		"angle": shooting_setup.angle,
		"power": shooting_setup.power,
		"position": shooting_setup.position
	})
	
	print("✅ [SHOOT_STATE] Tiro sincronizado para: ", shooter.name)

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
		var shooting_setup = ShootingSetup.new(angle, shoot_position, power, facing_left)
		sync_player_shot.rpc(shooter_index, shooting_setup.to_dict())
	else:
		print("❌ [SHOOT_STATE] Player ", player.name, " não pode atirar agora!")
	
	# Transita para waiting turn
	state_machine.change_state('waitingturn')

func execute(delta):
	pass

func exit():
	pass
