# Scripts/Terrain/crater_queue.gd
class_name CraterQueue extends RefCounted

# Dados da cratera para processar
class CraterRequest:
	var position: Vector2
	var hole_mask_path: String
	var texture_mask_path: String
	var callback: Callable  # Chamado quando terminar
	
	func _init(pos: Vector2, hole_path: String, texture_path: String, cb: Callable = Callable()):
		position = pos
		hole_mask_path = hole_path
		texture_mask_path = texture_path
		callback = cb

# Estado da queue
var _queue: Array[CraterRequest] = []
var _is_processing: bool = false

# Componentes necessários (injetados)
var mask_cache: MaskCache
var crater_processor: CraterProcessor
var terrain_renderer: TerrainRenderer

signal crater_processed(position: Vector2)
signal queue_finished()

func initialize(cache: MaskCache, processor: CraterProcessor, renderer: TerrainRenderer):
	"""Inicializa queue com dependências"""
	mask_cache = cache
	crater_processor = processor
	terrain_renderer = renderer
	print("🔄 [CRATER_QUEUE] Inicializada")

func add_crater_request(position: Vector2, hole_mask_path: String, texture_mask_path: String, callback: Callable = Callable()):
	"""Adiciona cratera na fila"""
	
	var request = CraterRequest.new(position, hole_mask_path, texture_mask_path, callback)
	_queue.append(request)
	
	print("🔄 [CRATER_QUEUE] Cratera adicionada na fila (", _queue.size(), " pendentes)")
	
	# Se não está processando, inicia
	if not _is_processing:
		_start_processing()

func _start_processing():
	"""Inicia processamento da fila"""
	
	if _queue.is_empty():
		return
	
	_is_processing = true
	print("🚀 [CRATER_QUEUE] Iniciando processamento...")
	
	_process_next_crater()

func _process_next_crater():
	"""Processa próxima cratera da fila"""
	
	if _queue.is_empty():
		_finish_processing()
		return
	
	var request = _queue.pop_front()
	print("🕳️ [CRATER_QUEUE] Processando cratera em ", request.position)
	
	# Carrega máscaras
	var hole_mask = mask_cache.load_mask_image(request.hole_mask_path)
	var texture_mask = mask_cache.load_mask_image(request.texture_mask_path)
	
	if not hole_mask or not texture_mask:
		print("❌ [CRATER_QUEUE] Erro ao carregar máscaras, pulando...")
		_on_crater_finished(request)
		return
	
	# Processa cratera
	var result = crater_processor.process_crater_masks(
		terrain_renderer.get_terrain_image(),
		terrain_renderer.get_terrain_bitmap(),
		request.position,
		hole_mask,
		texture_mask
	)
	
	# Atualiza visual
	terrain_renderer.update_all()
	
	print("✅ [CRATER_QUEUE] Cratera processada em ", result.processing_time_ms, "ms")
	
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
	print("🏁 [CRATER_QUEUE] Fila processada completamente")
	
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
	print("🧹 [CRATER_QUEUE] Fila limpa")
