# Scripts/TerrainV2/crater_queue_v2.gd
class_name CraterQueueV2 extends RefCounted

# Crater request data
class CraterRequest:
	var position: Vector2
	var explosion_data: Dictionary
	var callback: Callable
	
	func _init(pos: Vector2, data: Dictionary, cb: Callable):
		position = pos
		explosion_data = data
		callback = cb

# Queue state
var _queue: Array[CraterRequest] = []
var _is_processing: bool = false
var _processing_delay: float = 0.2  # 200ms between craters

func add_crater_request(position: Vector2, explosion_data: Dictionary, callback: Callable):
	"""Add crater to FIFO queue"""
	
	var request = CraterRequest.new(position, explosion_data, callback)
	_queue.append(request)
	
	print("🔄 [CRATER_QUEUE_V2] Added crater to queue (", _queue.size(), " pending)")
	
	# Start processing if not already running
	if not _is_processing:
		_start_processing()

func _start_processing():
	"""Start processing queue with delays"""
	
	if _queue.is_empty():
		return
	
	_is_processing = true
	print("🚀 [CRATER_QUEUE_V2] Starting queue processing...")
	
	_process_next_crater()

func _process_next_crater():
	"""Process next crater in queue"""
	
	if _queue.is_empty():
		_finish_processing()
		return
	
	var request = _queue.pop_front()
	print("💥 [CRATER_QUEUE_V2] Processing crater at: ", request.position)
	
	# Execute crater immediately
	request.callback.call(request.position, request.explosion_data)
	
	# Schedule next crater with delay
	if not _queue.is_empty():
		_schedule_next_crater()
	else:
		_finish_processing()

func _schedule_next_crater():
	"""Schedule next crater with 0.2s delay"""
	
	print("⏱️ [CRATER_QUEUE_V2] Scheduling next crater in ", _processing_delay, "s")
	
	# Create timer for delay
	var timer = Timer.new()
	timer.wait_time = _processing_delay
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	
	# Add to scene tree temporarily
	Engine.get_main_loop().current_scene.add_child(timer)
	timer.start()

func _on_timer_timeout():
	"""Timer callback - process next crater"""
	
	var timer = Engine.get_main_loop().current_scene.get_children().filter(func(child): return child is Timer and child.is_connected("timeout", _on_timer_timeout))
	
	if not timer.is_empty():
		timer[0].queue_free()
	
	_process_next_crater()

func _finish_processing():
	"""Finish queue processing"""
	
	_is_processing = false
	print("🏁 [CRATER_QUEUE_V2] Queue processing finished")

# ===== UTILITY METHODS =====

func get_queue_size() -> int:
	return _queue.size()

func is_processing() -> bool:
	return _is_processing

func clear_queue():
	"""Emergency clear queue"""
	_queue.clear()
	_is_processing = false
	print("🧹 [CRATER_QUEUE_V2] Queue cleared")
