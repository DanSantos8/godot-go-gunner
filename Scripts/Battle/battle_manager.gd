extends Node

# Signals para comunicação global
signal battle_started
signal turn_changed(player_index: int)
signal player_shot(player: Player)
signal explosion_occurred(position: Vector2, damage: float)
signal battle_ended(winner: Player)

var state_machine: BattleStateMachine

# Battle data
var players: Array[Player] = []
var current_player_index: int = 0
var turn_timer: float = 11
var max_turn_time: float = 11
var wind_force: Vector2 = Vector2.ZERO
var current_projectile: RigidBody2D = null

# Battle settings
var max_players: int = 2
var rounds_to_win: int = 1

var unlocked_players: Array[Player] = []

var player_scene = preload("res://Scenes/player.tscn")
var spawn_positions: Array[Vector2] = [
	Vector2(600, 500),   # Player 1 spawn
	Vector2(900, 500)    # Player 2 spawn
]


func _ready():
	print("🚀 [BATTLE_MANAGER] Initializing...")
	# Conecta com o ProjectileManager existente
	if ProjectileManager:
		# Vamos conectar eventos de projétil aqui depois
		pass

func _process(delta: float):
	if state_machine:
		state_machine.execute(delta)

# Inicialização da batalha
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
	var isMyTurn = get_current_player().network_id == player.network_id
	
	return is_player_unlocked(player) and isMyTurn
	
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

# Event handlers específicos
func _on_projectile_hit(projectile: RigidBody2D, position: Vector2):
	current_projectile = null
	if state_machine:
		state_machine.explosion_occurred()

# Debug methods
func debug_info():
	print("🎮 [BATTLE_MANAGER] Current player: ", current_player_index)
	print("🎮 [BATTLE_MANAGER] Turn timer: ", turn_timer)
	print("🎮 [BATTLE_MANAGER] Current state: ", state_machine.current_state.name if state_machine and state_machine.current_state else "none")

# ===== DYNAMIC PLAYER SPAWNING =====

func setup_players_multiplayer():
	print("🎮 [BATTLE] Setup players para multiplayer...")
	
	if not multiplayer.is_server():
		print("❌ [BATTLE] Só servidor pode spawnar players!")
		return
	
	# Limpar players existentes
	_clear_existing_players()
	
	# Spawnar players baseado em conexões
	_spawn_connected_players()

func _clear_existing_players():
	# Remove players que podem estar na cena
	for child in get_tree().current_scene.get_children():
		if child is Player:
			child.queue_free()

func _spawn_connected_players():
	var connected_peers = [1] # Server sempre é ID 1
	connected_peers.append_array(multiplayer.get_peers())
	
	print("🎮 [BATTLE] Players conectados: ", connected_peers)
	
	for i in range(min(connected_peers.size(), spawn_positions.size())):
		var peer_id = connected_peers[i]
		var spawn_pos = spawn_positions[i]
		var player_name = "Player" + str(i + 1)
		
		_spawn_player.rpc(peer_id, spawn_pos, player_name, i)

@rpc("authority", "call_local", "reliable")
func _spawn_player(network_id: int, position: Vector2, player_name: String, player_index: int):
	print("👤 [BATTLE] Spawnando ", player_name, " (ID: ", network_id, ") em ", position)
	
	# Criar player
	var player_instance = player_scene.instantiate()
	player_instance.network_id = network_id
	player_instance.name = player_name
	player_instance.set_multiplayer_authority(network_id)
	player_instance.global_position = position
	
	# Configurar network
	player_instance.set_multiplayer_authority(network_id)
	
	get_tree().current_scene.add_child(player_instance, true)
	
	# Registrar localmente
	if player_index < players.size():
		players[player_index] = player_instance
	else:
		players.append(player_instance)

# ===== NETWORK AUTHORITY =====
func is_authority() -> bool:
	return multiplayer.is_server() or multiplayer.get_unique_id() == 1

func log_network(message: String):
	var authority_status = "AUTHORITY" if is_authority() else "CLIENT"
	print("📡 [", authority_status, "] ", message)
