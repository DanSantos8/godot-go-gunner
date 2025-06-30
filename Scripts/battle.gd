extends Node

enum BattleState {
	WAITING,
	TURN,
	SHOOTING,
	ENDED
}

var current_state: BattleState = BattleState.WAITING
var players: Array = []
var current_player_index: int = 0

func _ready():
	print("🚀 Battle System iniciado")
