extends Node2D


func _ready():
	var players_list: Array[Player] = []
	BattleManager.start_battle(players_list)
