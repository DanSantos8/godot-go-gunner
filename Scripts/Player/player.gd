extends CharacterBody2D
class_name Player

signal player_flipped(flip_h: bool)

var network_id: int = -1


@onready var state_machine = $StateMachine
@onready var animated_sprite = $PlayerAnimation
@onready var weapon_pivot = $WeaponPivot
@onready var aim_line = $WeaponPivot/AimLine
@onready var power_bar = $PlayerUI/ProgressBar
@onready var aim_ui = $PlayerUI/AimUI
@onready var powerbar_label = $PlayerUI/PowerbarLabel
@onready var player_ui = $PlayerUI

var shooting_angle = 0
@export var gravity: float = 10000.0
@export var speed: float = 20.00

func _ready():
	state_machine.init(self)
	$Camera2D.enabled = false
	
func _process(delta: float):
	# Verifica se é o player LOCAL E se é seu turno
	var is_my_player = is_multiplayer_authority()  
	var is_my_turn = can_act()
	
	# HUD só aparece se for MEU player E minha vez
	player_ui.visible = is_my_player and is_my_turn
	
	if velocity.x != 0 and is_my_player and is_my_turn:
		animated_sprite.flip_h = velocity.x < 0
	
	# Scale visual para TODOS verem quem está ativo
	var target_scale = 1.15 if is_my_turn else 1.0
	scale = Vector2(target_scale, target_scale)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	
	if not can_act():
		return
		
	state_machine.execute(delta)
	
func can_act() -> bool:
	print("[CAN_ACT]: ", self, BattleManager.can_player_act(self))
	return BattleManager.can_player_act(self)
