class_name BattleState extends Node

var state_machine: BattleStateMachine
var battle_manager: BattleManager

func init(sm: BattleStateMachine, bm: BattleManager):
	state_machine = sm
	battle_manager = bm

func enter():
	pass

func execute(delta: float):
	pass

func exit():
	pass

# Métodos utilitários básicos
func get_current_player() -> Player:
	return battle_manager.get_current_player()

func log_state(message: String):
	print("🎮 [BATTLE] ", get_script().get_global_name(), " | ", message)
