# Scripts/terrain_bitmap.gd - V3.0 (Refatorado com componentes)
class_name TerrainBitmap extends StaticBody2D

# Referencias de nodes
var terrain_sprite: Sprite2D
var terrain_collision: CollisionPolygon2D

# ===== COMPONENTS =====
var mask_cache: MaskCache
var crater_processor: CraterProcessor
var terrain_renderer: TerrainRenderer
var crater_queue: CraterQueue
var _is_updating_texture: bool = false

func _ready():
	# Conecta signal de colisão do projétil
	MessageBus.projectile_collided_with_terrain.connect(_on_projectile_collision)
	
	# Busca os nodes filhos
	terrain_sprite = $TerrainSprite
	terrain_collision = $TerrainCollision
	
	if not terrain_sprite or not terrain_collision:
		return
	
	# Inicializa componentes
	mask_cache = MaskCache.new()
	crater_processor = CraterProcessor.new()
	terrain_renderer = TerrainRenderer.new()
	crater_queue = CraterQueue.new()
	
	# Inicializa renderer
	terrain_renderer.initialize(terrain_sprite, terrain_collision)
	
	# Inicializa queue com dependências
	crater_queue.initialize(mask_cache, crater_processor, terrain_renderer)
	
	# Setup inicial
	var texture = terrain_sprite.texture
	if texture:
		terrain_renderer.setup_from_texture(texture)



# ===== SIGNAL HANDLERS =====
func _on_projectile_collision(collision_position: Vector2):
	"""Cria cratera quando projétil colide"""
	
	var local_position = to_local(collision_position)
	
	# Adiciona cratera na queue ao invés de processar direto
	crater_queue.add_crater_request(
		local_position,
		"res://Sprites/Craters/hole-crater.png",
		"res://Sprites/Craters/grass-hole.png"
	)

# ===== API PÚBLICA V3.0 (COM CRATER_QUEUE) =====
func apply_crater_masks_optimized(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Aplica cratera usando queue (método mantido para compatibilidade)"""
	
	print("🔄 [TERRAIN] Adicionando cratera na queue...")
	crater_queue.add_crater_request(position, hole_mask_path, texture_mask_path)

func apply_crater_masks_with_callback(position: Vector2, hole_mask_path: String, texture_mask_path: String, callback: Callable):
	"""Nova API: aplica cratera com callback quando terminar"""
	
	print("🔄 [TERRAIN] Adicionando cratera com callback na queue...")
	crater_queue.add_crater_request(position, hole_mask_path, texture_mask_path, callback)

# ===== LEGACY PROCESSING (para casos especiais) =====
func apply_crater_immediate(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Processa cratera imediatamente (só usar em casos especiais!)"""
	
	if _is_updating_texture:
		print("⚠️ [TERRAIN] Update em andamento, usando queue...")
		apply_crater_masks_optimized(position, hole_mask_path, texture_mask_path)
		return
	
	_is_updating_texture = true
	
	print("⚡ [TERRAIN] Processamento imediato de cratera...")
	
	# Carrega as máscaras do cache
	var hole_mask = mask_cache.load_mask_image(hole_mask_path)
	var texture_mask = mask_cache.load_mask_image(texture_mask_path)
	
	if not hole_mask or not texture_mask:
		print("❌ [TERRAIN] Erro ao carregar máscaras!")
		_is_updating_texture = false
		return
	
	# Processa crateras usando renderer
	var result = crater_processor.process_crater_masks(
		terrain_renderer.get_terrain_image(), 
		terrain_renderer.get_terrain_bitmap(), 
		position, 
		hole_mask, 
		texture_mask
	)
	
	# Atualiza visual e colisão via renderer
	terrain_renderer.update_all()
	
	print("✅ [TERRAIN] Cratera imediata aplicada em ", result.processing_time_ms, "ms")
	print("   📊 Pixels: ", result.pixels_processed, " aplicados, ", result.pixels_removed, " removidos, ", result.pixels_skipped, " pulados")
	
	_is_updating_texture = false

# ===== MÉTODOS LEGADOS (compatibilidade) =====
func apply_crater_masks(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Método não-otimizado mantido para compatibilidade"""
	
	print("⚠️ [TERRAIN OPT] Usando método não-otimizado - considere usar apply_crater_masks_optimized()")
	apply_crater_masks_optimized(position, hole_mask_path, texture_mask_path)

func create_crater_at_position(world_position: Vector2, radius: float = 40.0):
	"""Método antigo mantido para compatibilidade"""
	
	print("⚠️ [TERRAIN OPT] Usando método circular legado")
	
	var sprite_size = terrain_renderer.get_terrain_size()
	var bitmap_position = world_position + sprite_size / 2.0
	
	var crater_bitmap = _create_circular_bitmap(bitmap_position, radius, terrain_renderer.get_terrain_bitmap().get_size())
	_subtract_from_terrain(crater_bitmap)
	terrain_renderer.update_collision()

func _create_circular_bitmap(center: Vector2, radius: float, bitmap_size: Vector2) -> BitMap:
	"""Cria BitMap circular (método antigo)"""
	
	var crater_bitmap = BitMap.new()
	crater_bitmap.create(bitmap_size)
	
	for y in range(max(0, center.y - radius), min(bitmap_size.y, center.y + radius)):
		for x in range(max(0, center.x - radius), min(bitmap_size.x, center.x + radius)):
			if Vector2(x, y).distance_to(center) <= radius:
				crater_bitmap.set_bit(x, y, true)
	
	return crater_bitmap

func _subtract_from_terrain(crater_bitmap: BitMap):
	"""Remove área da cratera do terreno (método antigo)"""
	
	var terrain_size = terrain_renderer.get_terrain_bitmap().get_size()
	var terrain_image = terrain_renderer.get_terrain_image()
	var terrain_bitmap = terrain_renderer.get_terrain_bitmap()
	
	for y in range(terrain_size.y):
		for x in range(terrain_size.x):
			if crater_bitmap.get_bit(x, y):
				terrain_bitmap.set_bit(x, y, false)
				terrain_image.set_pixel(x, y, Color.TRANSPARENT)
	
	terrain_renderer.update_visual()
