# Scripts/Battle/battle_state_machine.gd - UPDATED
class_name BattleStateMachine extends Node

var current_state: BattleState
var states: Dictionary = {}
var battle_manager: BattleManager

func init(battle_ref: BattleManager):
	battle_manager = battle_ref
	
	print("🔧 [BATTLE_SM] Scanning children...")
	print("🔧 [BATTLE_SM] Total children: ", get_children().size())
	
	# Registra todos os states filhos
	for child in get_children():
		print("🔧 [BATTLE_SM] Found child: ", child.name, " (type: ", child.get_class(), ")")
		
		if child is BattleState:
			var state_name = child.name.to_lower().replace("state", "")
			states[state_name] = child
			child.init(self, battle_ref)
			print("🔧 [BATTLE_SM] Registered state: ", state_name)
		else:
			print("🔧 [BATTLE_SM] Child is not BattleState: ", child.name)
	
	print("🔧 [BATTLE_SM] Final registered states: ", states.keys())
	
	# Inicia com setup
	if states.has("setup"):
		current_state = states["setup"]
		print("🎯 [BATTLE_SM] Starting with SetupState...")
		current_state.enter()
	else:
		print("❌ [BATTLE_SM] Setup state not found! Available states: ", states.keys())

func change_state(new_state_name: String):
	if not states.has(new_state_name):
		print("❌ [BATTLE_SM] State not found: ", new_state_name)
		return
	
	print("🔄 [BATTLE_SM] Changing state: ", current_state.name if current_state else "null", " → ", new_state_name)
	
	if current_state:
		current_state.exit()
	
	current_state = states[new_state_name]
	current_state.enter()

func execute(delta: float):
	if current_state:
		current_state.execute(delta)

# ===== CONVENIENCE METHODS =====

func start_turn():
	change_state("turnstart")

func wait_for_input():
	change_state("waitinginput")

func projectile_launched():
	change_state("projectileflying")

func explosion_occurred():
	change_state("explosion")

func end_turn():
	change_state("turnend")

func game_over():
	change_state("gameover")

# ===== PLAYER STATE COORDINATION =====

func activate_waiting_turn_for_inactive_players():
	"""Coloca players inativos em WaitingTurnState"""
	var current_player = battle_manager.get_current_player()
	
	for player in battle_manager.players:
		if player != current_player:
			# Força transição para WaitingTurnState
			if player.state_machine:
				player.state_machine.change_state("waitingturn")
				print("🔄 [BATTLE_SM] ", player.name, " → WaitingTurnState")

func deactivate_waiting_turn_for_all_players():
	"""Remove todos players do WaitingTurnState"""
	for player in battle_manager.players:
		if player.state_machine and player.state_machine.current_state.name == "WaitingTurnState":
			player.state_machine.change_state("idle")
			print("🔄 [BATTLE_SM] ", player.name, " → IdleState")
