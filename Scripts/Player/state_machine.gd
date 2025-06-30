class_name StateMachine extends Node

var current_state: State
var states: Dictionary = {}
var player: CharacterBody2D


func init(player_ref: CharacterBody2D):
	player = player_ref	
	for child in get_children():
		var state_name = child.name.to_lower().replace("state", "")
		states[state_name] = child
		child.init(self, player_ref)
	
	current_state = states['idle']
	current_state.enter()
		
func change_state(new_state_name: String):
	print("Change State: ", new_state_name)
	if current_state:
		current_state.exit()
	
	current_state = states[new_state_name]
	current_state.enter()

func execute(delta: float):
	if current_state:
		current_state.execute(delta)
