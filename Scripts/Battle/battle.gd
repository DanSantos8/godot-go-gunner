extends Node2D

func _ready():
	var players_list: Array[Player] = [get_node("Player")]
	BattleManager.start_battle(players_list)
