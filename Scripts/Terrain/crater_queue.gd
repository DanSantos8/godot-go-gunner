# Scripts/Terrain/crater_queue.gd - V2.0 (Sistema Procedural)
class_name CraterQueue extends RefCounted

# Dados da cratera para processar (ATUALIZADO)
class CraterRequest:
	var position: Vector2
	var destruction_shape: DestructionShape
	var callback: Callable  # Chamado quando terminar
	
	func _init(pos: Vector2, shape: DestructionShape, cb: Callable = Callable()):
		position = pos
		destruction_shape = shape
		callback = cb

# Estado da queue
var _queue: Array[CraterRequest] = []
var _is_processing: bool = false

# Referência ao TerrainBitmap (injetado)
var terrain_bitmap: TerrainBitmap

signal crater_processed(position: Vector2)
signal queue_finished()

func initialize(terrain_ref: TerrainBitmap):
	"""Inicializa queue com referência ao TerrainBitmap"""
	terrain_bitmap = terrain_ref
	print("🔄 [CRATER_QUEUE] Inicializada com sistema procedural")

func add_crater_request(position: Vector2, destruction_shape_or_rx, ry_or_callback = null, callback: Callable = Callable()):
	"""Adiciona cratera na fila - aceita DestructionShape ou valores legados"""
	
	var request: CraterRequest
	
	if destruction_shape_or_rx is DestructionShape:
		# Nova API: DestructionShape
		var callback_param = ry_or_callback if ry_or_callback is Callable else callback
		request = CraterRequest.new(position, destruction_shape_or_rx, callback_param)
	else:
		# API legada: radius_x, radius_y (para compatibilidade)
		var rx = destruction_shape_or_rx as float
		var ry = ry_or_callback as float if ry_or_callback is float else rx
		
		# Cria DestructionShape temporário
		var temp_shape = DestructionShape.new()
		temp_shape.shape_type = DestructionShape.ShapeType.OVAL if rx != ry else DestructionShape.ShapeType.CIRCLE
		temp_shape.size = Vector2(rx, ry)
		temp_shape.burn_multiplier = 1.5
		
		request = CraterRequest.new(position, temp_shape, callback)
	
	_queue.append(request)
	
	# Se não está processando, inicia
	if not _is_processing:
		_start_processing()

func _start_processing():
	"""Inicia processamento da fila"""
	
	if _queue.is_empty():
		return
	
	_is_processing = true
	_process_next_crater()

func _process_next_crater():
	"""Processa próxima cratera da fila"""
	
	if _queue.is_empty():
		_finish_processing()
		return
	
	var request = _queue.pop_front()
	
	# Valida referência do terrain
	if not terrain_bitmap:
		_on_crater_finished(request)
		return
	
	# Cria cratera usando DestructionShape
	var shape = request.destruction_shape
	
	match shape.shape_type:
		DestructionShape.ShapeType.CIRCLE:
			terrain_bitmap.create_elliptical_crater(
				request.position,
				shape.size.x,
				shape.size.x,  # Círculo: rx = ry
				shape.burn_multiplier
			)
		DestructionShape.ShapeType.OVAL:
			terrain_bitmap.create_elliptical_crater(
				request.position,
				shape.size.x,
				shape.size.y,
				shape.burn_multiplier
			)
		DestructionShape.ShapeType.RECTANGLE:
			# TODO: Implementar create_rectangular_crater() futuramente
			print("⚠️ [CRATER_QUEUE] RECTANGLE não implementado ainda, usando OVAL")
			terrain_bitmap.create_elliptical_crater(
				request.position,
				shape.size.x,
				shape.size.y,
				shape.burn_multiplier
			)
	
	# Finaliza esta cratera
	_on_crater_finished(request)

func _on_crater_finished(request: CraterRequest):
	"""Chamado quando uma cratera termina de processar"""
	
	# Emite signal
	crater_processed.emit(request.position)
	
	# Chama callback se fornecido
	if request.callback.is_valid():
		request.callback.call()
	
	# Processa próxima (se houver)
	_process_next_crater()

func _finish_processing():
	"""Finaliza processamento da fila"""
	
	_is_processing = false
	
	# Emite signal de fim
	queue_finished.emit()

# ===== UTILITY METHODS =====

func get_queue_size() -> int:
	"""Retorna tamanho atual da fila"""
	return _queue.size()

func is_processing() -> bool:
	"""Verifica se está processando"""
	return _is_processing

func clear_queue():
	"""Limpa fila (emergência)"""
	_queue.clear()
	_is_processing = false

# ===== MÉTODOS DE CONVENIÊNCIA =====

func add_small_crater(position: Vector2, callback: Callable = Callable()):
	"""Conveniência: Adiciona cratera pequena"""
	add_crater_request(position, 20.0, 30.0, callback)

func add_medium_crater(position: Vector2, callback: Callable = Callable()):
	"""Conveniência: Adiciona cratera média"""
	add_crater_request(position, 35.0, 50.0, callback)

func add_large_crater(position: Vector2, callback: Callable = Callable()):
	"""Conveniência: Adiciona cratera grande"""
	add_crater_request(position, 50.0, 70.0, callback)

# ===== DEBUG METHODS =====

func get_queue_info() -> Dictionary:
	"""Retorna informações da fila para debug"""
	var info = {
		"queue_size": _queue.size(),
		"is_processing": _is_processing,
		"terrain_available": terrain_bitmap != null
	}
	
	if not _queue.is_empty():
		var next_crater = _queue[0]
		info["next_crater"] = {
			"position": next_crater.position,
			"hole_radius": next_crater.hole_radius,
			"burn_radius": next_crater.burn_radius
		}
	
	return info
