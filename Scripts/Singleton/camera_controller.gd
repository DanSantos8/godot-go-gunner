extends Node

enum CameraState {
	FOLLOWING_PLAYER,
	FOLLOWING_PROJECTILE,
	TRANSITIONING
}

# Refs
var camera: Camera2D
var current_target: Node2D
var current_state: CameraState = CameraState.FOLLOWING_PLAYER

# Config
@export var follow_speed: float = 5.0
@export var projectile_follow_speed: float = 8.0
@export var transition_duration: float = 0.5
@export var camera_offset: Vector2 = Vector2(0, -50)
@export var projectile_lead_factor: float = 0.3  # Antecipa movimento do projétil

# Transition
var transition_timer: float = 0.0
var transition_from: Vector2
var transition_to: Node2D

func _ready():
	MessageBus.battle_event.connect(_on_battle_event)
	MessageBus.projectile_collision.connect(_on_projectile_collision)
	MessageBus.projectile_launched.connect(_on_projectile_launched)
	
	_setup_camera()

func _setup_camera():
	camera = Camera2D.new()
	camera.name = "BattleCamera"
	camera.zoom = Vector2(1.5, 1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = follow_speed
	add_child(camera)

func _process(delta: float):
	if not camera or not is_instance_valid(current_target):
		return
	
	match current_state:
		CameraState.FOLLOWING_PLAYER:
			_follow_target(current_target, follow_speed)
			
		CameraState.FOLLOWING_PROJECTILE:
			_follow_projectile(current_target, projectile_follow_speed)
			
		CameraState.TRANSITIONING:
			_process_transition(delta)

func _follow_target(target: Node2D, speed: float):
	var target_pos = target.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target_pos, speed * get_process_delta_time())

func _follow_projectile(projectile: Node2D, speed: float):
	if not projectile.has_method("get_linear_velocity"):
		_follow_target(projectile, speed)
		return
	
	# Antecipa movimento do projétil
	var velocity = projectile.linear_velocity
	var lead_offset = velocity * projectile_lead_factor
	var target_pos = projectile.global_position + lead_offset + camera_offset
	
	camera.global_position = camera.global_position.lerp(target_pos, speed * get_process_delta_time())

func _process_transition(delta: float):
	if not is_instance_valid(transition_to):
		print("⚠️ [CAMERA] Transition target destroyed, returning to player")
		return_to_current_player()
		return
		
	transition_timer += delta
	var t = transition_timer / transition_duration
	
	if t >= 1.0:
		# Transição completa
		current_state = CameraState.FOLLOWING_PROJECTILE
		current_target = transition_to
		transition_timer = 0.0
	else:
		# Interpola entre posições
		var eased_t = ease(t, -1.5)  # Ease out
		var target_pos = transition_to.global_position + camera_offset
		camera.global_position = transition_from.lerp(target_pos, eased_t)

# === PUBLIC METHODS ===

func set_target(new_target: Node2D, instant: bool = false):
	if not is_instance_valid(new_target):
		return
	
	current_target = new_target
	
	if instant:
		camera.global_position = new_target.global_position + camera_offset

func follow_player(player: Player):
	current_target = player
	current_state = CameraState.FOLLOWING_PLAYER
	print("📷 [CAMERA] Following player: ", player.name)

func follow_projectile(projectile: Node2D):
	if current_state == CameraState.FOLLOWING_PROJECTILE:
		return
	
	transition_from = camera.global_position
	transition_to = projectile
	transition_timer = 0.0
	current_state = CameraState.TRANSITIONING
	
	print("📷 [CAMERA] Transitioning to projectile")

func return_to_current_player():
	var current_player = BattleManager.get_current_player()
	if current_player:
		follow_player(current_player)

# === EVENT HANDLERS ===

func _on_projectile_launched(shooter: Player, shooting_setup: ShootingSetup):
	var projectile = ProjectileManager.current_projectile
	print("[ENTROU NO SIGNALLLLL]")
	if projectile:
		follow_projectile(projectile)

func _on_battle_event(event_type: String, data: Dictionary):
	match event_type:
		"projectile_destroyed":
			_on_projectile_destroyed(data.get("position"))
		"turn_started":
			var player = data.get("player")
			if player:
				follow_player(player)

func _on_projectile_collision(collision_type: String, position: Vector2, player_id: int):
	await get_tree().create_timer(1.0).timeout
	return_to_current_player()

# === UTILITY ===

func shake_camera(intensity: float = 10.0, duration: float = 0.5):
	pass

func zoom_to(new_zoom: Vector2, duration: float = 1.0):
	pass
	
func _on_projectile_destroyed(final_position: Vector2):
	print("📷 [CAMERA] Projectile destroyed, returning to player")

	if current_state == CameraState.TRANSITIONING:
		current_state = CameraState.FOLLOWING_PLAYER

	return_to_current_player()
