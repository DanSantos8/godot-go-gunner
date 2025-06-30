extends Node

var current_battle: Battle

signal battle_event(event_type: String, data: Dictionary)

func emit_battle_event(event_type: String, data: Dictionary):
	battle_event.emit(event_type, data)
	print("🎮 [BATTLE] ", event_type, " | ", data) #debug
