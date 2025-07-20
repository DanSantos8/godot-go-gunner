# Scripts/terrain_bitmap.gd - V2.1 (Otimizado)
class_name TerrainBitmap extends StaticBody2D

# Referencias de nodes
var terrain_sprite: Sprite2D
var terrain_collision: CollisionPolygon2D

# Dados internos
var terrain_bitmap: BitMap
var terrain_image: Image
var terrain_texture: ImageTexture 

# ===== CACHE DE MÁSCARAS (OTIMIZAÇÃO) =====
var _mask_cache: Dictionary = {}
var _is_updating_texture: bool = false

func _ready():
	# Conecta signal de colisão do projétil
	MessageBus.projectile_collided_with_terrain.connect(_on_projectile_collision)
	
	# Busca os nodes filhos
	terrain_sprite = $TerrainSprite
	terrain_collision = $TerrainCollision
	
	if not terrain_sprite or not terrain_collision:
		return
	
	# Setup inicial
	var texture = terrain_sprite.texture
	if texture:
		_create_bitmap_from_texture(texture)
		_generate_collision()
	
	# Pre-carrega máscaras comuns para cache
	_preload_common_masks()

func _create_bitmap_from_texture(texture: Texture2D):
	"""Converte textura para BitMap editável"""
	
	# Cria cópia editável da imagem
	terrain_image = texture.get_image().duplicate()
	terrain_texture = ImageTexture.new()
	terrain_texture.set_image(terrain_image)
	terrain_sprite.texture = terrain_texture
	
	# Cria bitmap para colisão
	terrain_bitmap = BitMap.new()
	terrain_bitmap.create_from_image_alpha(terrain_image, 0.1)

func _generate_collision():
	"""Gera CollisionPolygon2D do BitMap"""
	
	if not terrain_bitmap:
		return
	
	# Converte bitmap para polígonos
	var rect = Rect2(Vector2.ZERO, terrain_bitmap.get_size())
	var polygons = terrain_bitmap.opaque_to_polygons(rect, 2.0)
	
	if polygons.is_empty():
		return
	
	# Centraliza coordenadas e aplica
	var sprite_size = terrain_sprite.texture.get_size()
	var offset = sprite_size / 2.0
	
	var centered_polygon = PackedVector2Array()
	for point in polygons[0]:
		centered_polygon.append(point - offset)
	
	terrain_collision.polygon = centered_polygon

# ===== CACHE SYSTEM (OTIMIZAÇÃO) =====
func _preload_common_masks():
	"""Pre-carrega máscaras comuns no cache"""
	
	print("🔄 [TERRAIN OPT] Pre-carregando máscaras...")
	
	var common_masks = [
		"res://Sprites/Craters/hole-crater.png",
		"res://Sprites/Craters/grass-hole.png"
	]
	
	for mask_path in common_masks:
		_load_mask_image_cached(mask_path)
	
	print("✅ [TERRAIN OPT] Cache inicializado com ", _mask_cache.size(), " máscaras")

func _load_mask_image_cached(path: String) -> Image:
	"""Carrega máscara com cache"""
	
	# Se já está no cache, retorna
	if _mask_cache.has(path):
		return _mask_cache[path]
	
	# Carrega e valida
	if not ResourceLoader.exists(path):
		print("❌ [TERRAIN OPT] Arquivo não encontrado: ", path)
		return null
	
	var texture = load(path) as Texture2D
	if not texture:
		print("❌ [TERRAIN OPT] Erro ao carregar textura: ", path)
		return null
	
	var image = texture.get_image()
	if not image:
		print("❌ [TERRAIN OPT] Erro ao extrair imagem: ", path)
		return null
	
	# Adiciona ao cache
	_mask_cache[path] = image
	print("💾 [TERRAIN OPT] Máscara armazenada no cache: ", path, " (", image.get_size(), ")")
	
	return image

# ===== SIGNAL HANDLERS =====
func _on_projectile_collision(collision_position: Vector2):
	"""Cria cratera quando projétil colide"""
	
	var local_position = to_local(collision_position)
	
	# Aplica crateras usando máscaras PNG (versão otimizada)
	apply_crater_masks_optimized(
		local_position,
		"res://Sprites/Craters/hole-crater.png",
		"res://Sprites/Craters/grass-hole.png"
	)

# ===== API PÚBLICA V2.1 (OTIMIZADA) =====
func apply_crater_masks_optimized(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Aplica cratera usando 2 máscaras PNG com otimizações"""
	
	if _is_updating_texture:
		print("⚠️ [TERRAIN OPT] Update em andamento, ignorando...")
		return
	
	_is_updating_texture = true
	
	print("🚀 [TERRAIN OPT] Aplicando crateras otimizadas...")
	var start_time = Time.get_ticks_msec()
	
	# Carrega as máscaras do cache
	var hole_mask = _load_mask_image_cached(hole_mask_path)
	var texture_mask = _load_mask_image_cached(texture_mask_path)
	
	if not hole_mask or not texture_mask:
		print("❌ [TERRAIN OPT] Erro ao carregar máscaras!")
		_is_updating_texture = false
		return
	
	# Converte posição world para bitmap coordinates
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_position = position + sprite_size / 2.0
	
	# Calcula bounding box otimizada (maior máscara determina área)
	var max_mask_size = Vector2(
		max(hole_mask.get_size().x, texture_mask.get_size().x),
		max(hole_mask.get_size().y, texture_mask.get_size().y)
	)
	
	var processing_area = _calculate_processing_area(bitmap_position, max_mask_size)
	
	# Aplica as máscaras na área otimizada
	_apply_texture_mask_optimized(bitmap_position, texture_mask, processing_area)
	_apply_hole_mask_optimized(bitmap_position, hole_mask, processing_area)
	
	# Atualiza textura uma vez só
	terrain_texture.update(terrain_image)
	_generate_collision()
	
	var end_time = Time.get_ticks_msec()
	var elapsed_ms = end_time - start_time
	
	print("✅ [TERRAIN OPT] Cratera aplicada em ", elapsed_ms, "ms")
	_is_updating_texture = false

# ===== MÉTODOS OTIMIZADOS =====
func _calculate_processing_area(center_position: Vector2, mask_size: Vector2) -> Rect2i:
	"""Calcula área mínima necessária para processamento"""
	
	var terrain_size = terrain_image.get_size()
	
	# Área ao redor do centro
	var half_size = mask_size / 2
	var start_x = max(0, int(center_position.x - half_size.x))
	var start_y = max(0, int(center_position.y - half_size.y))
	var end_x = min(terrain_size.x, int(center_position.x + half_size.x))
	var end_y = min(terrain_size.y, int(center_position.y + half_size.y))
	
	var area = Rect2i(start_x, start_y, end_x - start_x, end_y - start_y)
	print("📐 [TERRAIN OPT] Área de processamento: ", area, " (", area.size.x * area.size.y, " pixels)")
	
	return area

func _apply_texture_mask_optimized(center_position: Vector2, texture_mask: Image, processing_area: Rect2i):
	"""Aplica textura de fundo com área limitada - SÓ onde já havia terreno"""
	
	var mask_size = texture_mask.get_size()
	var mask_start = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🎨 [TERRAIN OPT] Aplicando textura na área ", processing_area.size)
	
	var pixels_processed = 0
	var pixels_skipped = 0
	
	# Só processa pixels dentro da área otimizada
	for terrain_y in range(processing_area.position.y, processing_area.position.y + processing_area.size.y):
		for terrain_x in range(processing_area.position.x, processing_area.position.x + processing_area.size.x):
			# Calcula posição correspondente na máscara
			var mask_x = int(terrain_x - mask_start.x)
			var mask_y = int(terrain_y - mask_start.y)
			
			# Verifica se está dentro da máscara
			if mask_x < 0 or mask_x >= mask_size.x or mask_y < 0 or mask_y >= mask_size.y:
				continue
			
			# Pega pixel da máscara
			var mask_pixel = texture_mask.get_pixel(mask_x, mask_y)
			
			# Se pixel da máscara não é transparente, verifica se pode aplicar
			if mask_pixel.a > 0.1:
				# 🔥 NOVO: Só aplica SE já havia terreno ali antes
				var existing_pixel = terrain_image.get_pixel(terrain_x, terrain_y)
				
				if existing_pixel.a > 0.1:  # Se não é transparente/ar
					terrain_image.set_pixel(terrain_x, terrain_y, mask_pixel)
					pixels_processed += 1
				else:
					pixels_skipped += 1  # Pulou porque era ar/transparente
	
	print("✅ [TERRAIN OPT] Textura aplicada: ", pixels_processed, " pixels (", pixels_skipped, " pulados por serem ar)")

func _apply_hole_mask_optimized(center_position: Vector2, hole_mask: Image, processing_area: Rect2i):
	"""Remove buraco com área limitada"""
	
	var mask_size = hole_mask.get_size()
	var mask_start = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🕳️ [TERRAIN OPT] Removendo buraco na área ", processing_area.size)
	
	var pixels_removed = 0
	
	# Só processa pixels dentro da área otimizada
	for terrain_y in range(processing_area.position.y, processing_area.position.y + processing_area.size.y):
		for terrain_x in range(processing_area.position.x, processing_area.position.x + processing_area.size.x):
			# Calcula posição correspondente na máscara
			var mask_x = int(terrain_x - mask_start.x)
			var mask_y = int(terrain_y - mask_start.y)
			
			# Verifica se está dentro da máscara
			if mask_x < 0 or mask_x >= mask_size.x or mask_y < 0 or mask_y >= mask_size.y:
				continue
			
			# Pega pixel da máscara
			var mask_pixel = hole_mask.get_pixel(mask_x, mask_y)
			
			# Se pixel é preto (buraco), remove do terreno
			if _is_black_pixel(mask_pixel):
				# Remove da imagem (visual)
				terrain_image.set_pixel(terrain_x, terrain_y, Color.TRANSPARENT)
				# Remove do bitmap (colisão)
				terrain_bitmap.set_bit(terrain_x, terrain_y, false)
				pixels_removed += 1
	
	print("✅ [TERRAIN OPT] Buraco removido: ", pixels_removed, " pixels")

func _is_black_pixel(pixel: Color) -> bool:
	"""Verifica se pixel é considerado preto (para remoção)"""
	
	var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
	return brightness < 0.2 and pixel.a > 0.5

# ===== MÉTODOS LEGADOS (compatibilidade) =====
func apply_crater_masks(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Método não-otimizado mantido para compatibilidade"""
	
	print("⚠️ [TERRAIN OPT] Usando método não-otimizado - considere usar apply_crater_masks_optimized()")
	apply_crater_masks_optimized(position, hole_mask_path, texture_mask_path)

func create_crater_at_position(world_position: Vector2, radius: float = 40.0):
	"""Método antigo mantido para compatibilidade"""
	
	print("⚠️ [TERRAIN OPT] Usando método circular legado")
	
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_position = world_position + sprite_size / 2.0
	
	var crater_bitmap = _create_circular_bitmap(bitmap_position, radius, terrain_bitmap.get_size())
	_subtract_from_terrain(crater_bitmap)
	_generate_collision()

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
	
	var terrain_size = terrain_bitmap.get_size()
	
	for y in range(terrain_size.y):
		for x in range(terrain_size.x):
			if crater_bitmap.get_bit(x, y):
				terrain_bitmap.set_bit(x, y, false)
				terrain_image.set_pixel(x, y, Color.TRANSPARENT)
	
	terrain_texture.update(terrain_image)
