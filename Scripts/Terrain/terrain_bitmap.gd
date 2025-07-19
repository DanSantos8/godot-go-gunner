# Scripts/terrain_bitmap.gd
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
	create_crater_at_position(local_position, 40.0)

# ===== API PÚBLICA =====

func create_crater_at_position(world_position: Vector2, radius: float = 40.0):
	"""Cria cratera circular na posição especificada"""
	
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_position = world_position + sprite_size / 2.0
	
	# Cria e aplica cratera
	var crater_bitmap = _create_circular_bitmap(bitmap_position, radius, terrain_bitmap.get_size())
	_subtract_from_terrain(crater_bitmap)
	_generate_collision()

# ===== MÉTODOS INTERNOS =====

func _create_circular_bitmap(center: Vector2, radius: float, bitmap_size: Vector2) -> BitMap:
	"""Cria BitMap circular"""
	
	var crater_bitmap = BitMap.new()
	crater_bitmap.create(bitmap_size)
	
	for y in range(max(0, center.y - radius), min(bitmap_size.y, center.y + radius)):
		for x in range(max(0, center.x - radius), min(bitmap_size.x, center.x + radius)):
			if Vector2(x, y).distance_to(center) <= radius:
				crater_bitmap.set_bit(x, y, true)
	
	return crater_bitmap

func _subtract_from_terrain(crater_bitmap: BitMap):
	"""Remove área da cratera do terreno (visual e colisão)"""
	
	var terrain_size = terrain_bitmap.get_size()
	
	for y in range(terrain_size.y):
		for x in range(terrain_size.x):
			if crater_bitmap.get_bit(x, y):
				terrain_bitmap.set_bit(x, y, false)
				terrain_image.set_pixel(x, y, Color.TRANSPARENT)
	
	# Atualiza textura
	terrain_texture.update(terrain_image)
