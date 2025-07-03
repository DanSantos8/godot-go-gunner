extends Node

# Signals para comunicação global
signal battle_started
signal turn_changed(player_index: int)
signal player_shot(player: Player)
signal explosion_occurred(position: Vector2, damage: float)
signal battle_ended(winner: Player)

# Referencias da state machine (será criada dinamicamente ou na cena)
var state_machine: BattleStateMachine

# Battle data
var players: Array[Player] = []
var current_player_index: int = 0
var turn_timer: float = 30.0
var max_turn_time: float = 30.0
var wind_force: Vector2 = Vector2.ZERO
var current_projectile: RigidBody2D = null

# Battle settings
var max_players: int = 2
var rounds_to_win: int = 1

var unlocked_players: Array[Player] = []

func _ready():
	print("🚀 [BATTLE_MANAGER] Initializing...")
	# Conecta com o ProjectileManager existente
	if ProjectileManager:
		# Vamos conectar eventos de projétil aqui depois
		pass

func _connect_message_bus_events():
	# Conecta eventos específicos ao invés do genérico
	MessageBus.projectile_hit.connect(_on_projectile_hit)
	MessageBus.player_shot.connect(_on_player_shot)
	MessageBus.terrain_destroyed.connect(_on_terrain_destroyed)
	
	print("📡 [BATTLE_MANAGER] Connected to MessageBus events")

func _process(delta: float):
	if state_machine:
		state_machine.execute(delta)

# Inicialização da batalha - VERSÃO CORRIGIDA
func start_battle(player_list: Array[Player] = []):
	print("🎯 [BATTLE_MANAGER] Starting battle initialization...")
	
	# Se nenhum player foi passado, deixa SetupState encontrar
	if player_list.size() > 0:
		players = player_list
		print("🎯 [BATTLE_MANAGER] Using provided players: ", players.size())
	else:
		print("🎯 [BATTLE_MANAGER] No players provided, SetupState will find them")
	
	current_player_index = 0
	turn_timer = max_turn_time
	
	# BUSCA a StateMachine na cena atual ao invés de criar
	if not state_machine:
		state_machine = _find_battle_state_machine()
		
		if not state_machine:
			print("❌ [BATTLE_MANAGER] BattleStateMachine not found in scene!")
			print("   Certifique-se de ter um node BattleStateMachine na cena")
			return false
	
	state_machine.init(self)
	
	# SetupState será responsável por validar e configurar players
	battle_started.emit()
	return true

# Novo método para encontrar a StateMachine na cena
func _find_battle_state_machine() -> BattleStateMachine:
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("❌ [BATTLE_MANAGER] No current scene found")
		return null
	
	# Busca recursiva por BattleStateMachine
	return _recursive_find_state_machine(current_scene)

func _recursive_find_state_machine(node: Node) -> BattleStateMachine:
	# Verifica se o próprio node é uma BattleStateMachine
	if node is BattleStateMachine:
		print("✅ [BATTLE_MANAGER] Found BattleStateMachine: ", node.name)
		return node
	
	# Busca nos filhos
	for child in node.get_children():
		var result = _recursive_find_state_machine(child)
		if result:
			return result
	
	return null

# Novo método para validação (usado pelo SetupState)
func validate_battle_ready() -> bool:
	if players.size() < 2:
		print("❌ [BATTLE_MANAGER] Need at least 2 players! Current: ", players.size())
		return false
	
	print("✅ [BATTLE_MANAGER] Battle ready with ", players.size(), " players")
	MessageBus.emit_battle_event("battle_started", {"players": players})
	return true

# Métodos utilitários para os states
func get_current_player() -> Player:
	if players.size() > 0 and current_player_index < players.size():
		return players[current_player_index]
	return null

func next_player():
	current_player_index = (current_player_index + 1) % players.size()
	turn_changed.emit(current_player_index)

func get_next_player_index() -> int:
	return (current_player_index + 1) % players.size()

func lock_all_players():
	unlocked_players.clear()
	print("🔒 [BATTLE_MANAGER] Todos players bloqueados")

func unlock_player(player: Player):
	unlocked_players.clear()
	unlocked_players.append(player)
	print("🔓 [BATTLE_MANAGER] Player desbloqueado: " + player.name)
	
func is_player_unlocked(player: Player) -> bool:
	return player in unlocked_players

func can_player_act(player: Player) -> bool:
	return is_player_unlocked(player)
	
func get_alive_players() -> Array[Player]:
	var alive: Array[Player] = []
	for player in players:
		# TODO: Implementar sistema de health
		# Por enquanto, considera todos vivos
		alive.append(player)
	return alive

func is_battle_over() -> bool:
	# TODO: Implementar quando tivermos health system
	return false  # Por enquanto, batalha nunca acaba

func get_winner() -> Player:
	var alive = get_alive_players()
	return alive[0] if alive.size() == 1 else null

# Event handlers específicos
func _on_projectile_hit(projectile: RigidBody2D, position: Vector2):
	current_projectile = null
	if state_machine:
		state_machine.explosion_occurred()

func _on_player_shot(player: Player, angle: float, power: float):
	if state_machine:
		state_machine.projectile_launched()

func _on_terrain_destroyed(position: Vector2, radius: float):
	# Processar efeitos da destruição do terreno
	pass

# Eventos do MessageBus (método genérico mantido para compatibilidade)
func _on_battle_event(event_type: String, data: Dictionary):
	match event_type:
		"projectile_launched":
			if state_machine:
				state_machine.projectile_launched()
		"projectile_hit":
			if state_machine:
				state_machine.explosion_occurred()
		"player_damaged":
			# Processar dano aqui
			pass

# Debug methods
func debug_info():
	print("🎮 [BATTLE_MANAGER] Current player: ", current_player_index)
	print("🎮 [BATTLE_MANAGER] Turn timer: ", turn_timer)
	print("🎮 [BATTLE_MANAGER] Current state: ", state_machine.current_state.name if state_machine and state_machine.current_state else "none")
