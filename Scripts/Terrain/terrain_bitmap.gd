# Scripts/terrain_bitmap.gd - V2.0
class_name TerrainBitmap extends StaticBody2D

# Referencias de nodes
var terrain_sprite: Sprite2D
var terrain_collision: CollisionPolygon2D

# Dados internos
var terrain_bitmap: BitMap
var terrain_image: Image
var terrain_texture: ImageTexture 

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

# ===== SIGNAL HANDLERS =====
func _on_projectile_collision(collision_position: Vector2):
	"""Cria cratera quando projétil colide"""
	
	var local_position = to_local(collision_position)
	
	# Aplica crateras usando máscaras PNG
	apply_crater_masks(
		local_position,
		"res://Sprites/Craters/hole-crater.png",
		"res://Sprites/Craters/grass-hole.png"
	)

# ===== API PÚBLICA V2.0 =====
func apply_crater_masks(position: Vector2, hole_mask_path: String, texture_mask_path: String):
	"""Aplica cratera usando 2 máscaras PNG"""
	
	print("🕳️ [TERRAIN V2] Aplicando crateras com máscaras...")
	print("   Posição: ", position)
	print("   Hole: ", hole_mask_path)
	print("   Texture: ", texture_mask_path)
	
	# Carrega as máscaras
	var hole_mask = _load_mask_image(hole_mask_path)
	var texture_mask = _load_mask_image(texture_mask_path)
	
	if not hole_mask or not texture_mask:
		print("❌ [TERRAIN V2] Erro ao carregar máscaras!")
		return
	
	# Converte posição world para bitmap coordinates
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_position = position + sprite_size / 2.0
	
	# Aplica as máscaras na ordem correta
	_apply_texture_mask(bitmap_position, texture_mask)  # Primeiro: textura de fundo
	_apply_hole_mask(bitmap_position, hole_mask)        # Segundo: remove buraco
	
	# Atualiza textura e colisão uma vez só
	terrain_texture.update(terrain_image)
	_generate_collision()
	
	print("✅ [TERRAIN V2] Cratera aplicada com sucesso!")

# ===== MÉTODOS INTERNOS V2.0 =====
func _load_mask_image(path: String) -> Image:
	"""Carrega e valida imagem de máscara"""
	
	if not ResourceLoader.exists(path):
		print("❌ [TERRAIN V2] Arquivo não encontrado: ", path)
		return null
	
	var texture = load(path) as Texture2D
	if not texture:
		print("❌ [TERRAIN V2] Erro ao carregar textura: ", path)
		return null
	
	var image = texture.get_image()
	if not image:
		print("❌ [TERRAIN V2] Erro ao extrair imagem: ", path)
		return null
	
	print("✅ [TERRAIN V2] Máscara carregada: ", path, " (", image.get_size(), ")")
	return image

func _apply_texture_mask(center_position: Vector2, texture_mask: Image):
	"""Aplica textura de fundo da cratera (grass-hole.png)"""
	
	var mask_size = texture_mask.get_size()
	var terrain_size = terrain_image.get_size()
	
	# Calcula área de aplicação (centralizada)
	var start_pos = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🎨 [TERRAIN V2] Aplicando textura de fundo...")
	print("   Centro: ", center_position, " | Máscara: ", mask_size)
	
	# Aplica pixel por pixel
	for mask_y in range(mask_size.y):
		for mask_x in range(mask_size.x):
			var terrain_x = int(start_pos.x + mask_x)
			var terrain_y = int(start_pos.y + mask_y)
			
			# Verifica limites do terreno
			if terrain_x < 0 or terrain_x >= terrain_size.x or terrain_y < 0 or terrain_y >= terrain_size.y:
				continue
			
			# Pega pixel da máscara
			var mask_pixel = texture_mask.get_pixel(mask_x, mask_y)
			
			# Se pixel da máscara não é transparente, aplica
			if mask_pixel.a > 0.1:
				terrain_image.set_pixel(terrain_x, terrain_y, mask_pixel)

func _apply_hole_mask(center_position: Vector2, hole_mask: Image):
	"""Remove buraco usando máscara preta (hole-crater.png)"""
	
	var mask_size = hole_mask.get_size()
	var terrain_size = terrain_image.get_size()
	
	# Calcula área de aplicação (centralizada)
	var start_pos = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🕳️ [TERRAIN V2] Removendo buraco...")
	print("   Centro: ", center_position, " | Máscara: ", mask_size)
	
	# Remove pixel por pixel
	for mask_y in range(mask_size.y):
		for mask_x in range(mask_size.x):
			var terrain_x = int(start_pos.x + mask_x)
			var terrain_y = int(start_pos.y + mask_y)
			
			# Verifica limites do terreno
			if terrain_x < 0 or terrain_x >= terrain_size.x or terrain_y < 0 or terrain_y >= terrain_size.y:
				continue
			
			# Pega pixel da máscara
			var mask_pixel = hole_mask.get_pixel(mask_x, mask_y)
			
			# Se pixel é preto (buraco), remove do terreno
			if _is_black_pixel(mask_pixel):
				# Remove da imagem (visual)
				terrain_image.set_pixel(terrain_x, terrain_y, Color.TRANSPARENT)
				# Remove do bitmap (colisão)
				terrain_bitmap.set_bit(terrain_x, terrain_y, false)

func _is_black_pixel(pixel: Color) -> bool:
	"""Verifica se pixel é considerado preto (para remoção)"""
	
	# Considera preto se RGB são baixos e alpha é alto
	var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
	return brightness < 0.2 and pixel.a > 0.5

# ===== MÉTODOS LEGADOS (compatibilidade) =====
func create_crater_at_position(world_position: Vector2, radius: float = 40.0):
	"""Método antigo mantido para compatibilidade"""
	
	print("⚠️ [TERRAIN V2] Usando método legado - considere migrar para apply_crater_masks()")
	
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
