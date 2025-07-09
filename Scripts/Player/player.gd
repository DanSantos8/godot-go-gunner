extends CharacterBody2D
class_name Player

signal player_flipped(flip_h: bool)

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
	
func _process(delta: float):
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
	
	var is_active = can_act()
	player_ui.visible = is_active
	var target_scale = 1.15 if is_active else 1.0
	scale = Vector2(target_scale, target_scale)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	
	if not can_act():
		return
		
	state_machine.execute(delta)
	
func can_act() -> bool:
	return BattleManager.can_player_act(self)
