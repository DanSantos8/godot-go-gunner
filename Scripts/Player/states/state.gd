class_name State extends Node

var state_machine: StateMachine
var player: CharacterBody2D

func init(sm: StateMachine, player_ref: CharacterBody2D):
	state_machine = sm
	player = player_ref

func enter():
	pass

func execute(delta: float):
	pass

func exit():
	pass
