extends Node2D

func _ready() -> void:
	BattleManager.set_process(false)
	NetworkManager.set_process(false)
