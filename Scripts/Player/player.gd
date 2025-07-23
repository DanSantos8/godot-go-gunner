class_name Player extends CharacterBody2D

signal player_flipped()

var network_id: int = -1

@export var player_stats: CharacterResource

@onready var state_machine = $StateMachine
@onready var animated_sprite = $PlayerAnimation
@onready var weapon_pivot = $WeaponPivot
@onready var aim_line = $WeaponPivot/AimLine
@onready var power_bar = $PlayerUI/ProgressBar
@onready var aim_ui = $PlayerUI/AimUI
@onready var powerbar_label = $PlayerUI/PowerbarLabel
@onready var player_ui = $PlayerUI
@onready var health_component = $HealthComponent
@onready var stamina_label = $PlayerUI/StaminaLabel
@onready var powerups = $PlayerUI/SidePanelPowerups

var shooting_angle = 0
const GRAVITY: float = 150.0
const SPEED: float = 20.00
var distance_accumulator: float = 0.0

# ===== SISTEMA DE STAMINA =====
var current_stamina: int = 0:
	set(value):
		var old_stamina = current_stamina
		current_stamina = max(0, min(value, _get_max_stamina()))
		
		if current_stamina != old_stamina:
			update_stamina_ui()

func _ready():
	state_machine.init(self)
	$Camera2D.enabled = false
	
	health_component.character_resource = player_stats
	current_stamina = _get_max_stamina()
	
func _process(delta: float):
	var is_my_player = is_multiplayer_authority()
	var is_my_turn = can_act()
	
	if is_my_player and is_my_turn:
		var input_direction = Input.get_axis("move_left", "move_right")
		if input_direction != 0:
			animated_sprite.flip_h = input_direction < 0
			update_aim_visual()
	
	# Resto do código original...
	player_ui.visible = is_my_player
	powerups.visible = is_my_turn and is_my_player
	weapon_pivot.visible = is_my_player and is_my_turn

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	
	# Só processa input se for MEU player E meu turno
	var is_my_player = is_multiplayer_authority()
	var is_my_turn = can_act()
	
	if not (is_my_player and is_my_turn):
		return
		
	state_machine.execute(delta)

func can_act() -> bool:
	return BattleManager.can_player_act(self)

func _get_max_stamina() -> int:
	if player_stats:
		return player_stats.stamina
	return 250

func update_stamina_ui():
	if stamina_label:
		stamina_label.text = "Stamina: " + str(current_stamina) + "/" + str(_get_max_stamina())

func has_stamina(amount: int = 1) -> bool:
	return current_stamina >= amount

func consume_stamina(amount: int) -> bool:
	if not has_stamina(amount):
		return false
	
	current_stamina -= amount
	return true

func restore_stamina_full():
	distance_accumulator = 0.0
	current_stamina = _get_max_stamina()
	
func update_aim_visual():
	if !animated_sprite.flip_h:
		weapon_pivot.rotation_degrees = shooting_angle
		weapon_pivot.scale.y = 1
		weapon_pivot.position.x = 8
	else:
		weapon_pivot.rotation_degrees = 180 - shooting_angle
		weapon_pivot.scale.y = -1
		weapon_pivot.position.x = -8
