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

var shooting_angle = 0

func _ready():
	print("Player _ready() executando...")
	print("StateMachine existe? ", state_machine != null)
	state_machine.init(self)
	print("Init chamado com sucesso!")
	
func _process(delta: float):
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _physics_process(delta: float) -> void:
	if not can_act():
		return
		
	state_machine.execute(delta)
	
func can_act() -> bool:
	return BattleManager.can_player_act(self)
