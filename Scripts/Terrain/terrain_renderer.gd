# Scripts/Terrain/terrain_renderer.gd
class_name TerrainRenderer extends RefCounted

# Referencias dos nodes (passadas pelo TerrainBitmap)
var terrain_sprite: Sprite2D
var terrain_collision: CollisionPolygon2D

# Dados de renderização
var terrain_bitmap: BitMap
var terrain_image: Image
var terrain_texture: ImageTexture

func initialize(sprite_node: Sprite2D, collision_node: CollisionPolygon2D):
	"""Inicializa renderer com referencias dos nodes"""
	terrain_sprite = sprite_node
	terrain_collision = collision_node
	
	print("🎨 [TERRAIN_RENDERER] Inicializado")

func setup_from_texture(source_texture: Texture2D) -> bool:
	"""Configura terreno a partir de uma textura"""
	
	if not source_texture:
		print("❌ [TERRAIN_RENDERER] Textura não fornecida")
		return false
	
	print("🎨 [TERRAIN_RENDERER] Configurando terreno da textura...")
	
	# Cria dados editáveis
	_create_editable_data(source_texture)
	
	# Gera colisão inicial
	generate_collision()
	
	print("✅ [TERRAIN_RENDERER] Terreno configurado")
	return true

func _create_editable_data(source_texture: Texture2D):
	"""Cria cópia editável da textura"""
	
	# Cria cópia editável da imagem
	terrain_image = source_texture.get_image().duplicate()
	terrain_texture = ImageTexture.new()
	terrain_texture.set_image(terrain_image)
	terrain_sprite.texture = terrain_texture
	
	# Cria bitmap para colisão
	terrain_bitmap = BitMap.new()
	terrain_bitmap.create_from_image_alpha(terrain_image, 0.1)
	
	print("🎨 [TERRAIN_RENDERER] Dados editáveis criados (", terrain_image.get_size(), ")")

func generate_collision():
	"""Gera CollisionPolygon2D do BitMap atual"""
	
	if not terrain_bitmap:
		print("❌ [TERRAIN_RENDERER] BitMap não existe")
		return
	
	# Converte bitmap para polígonos
	var rect = Rect2(Vector2.ZERO, terrain_bitmap.get_size())
	var polygons = terrain_bitmap.opaque_to_polygons(rect, 2.0)
	
	if polygons.is_empty():
		print("⚠️ [TERRAIN_RENDERER] Nenhum polígono gerado")
		return
	
	# Centraliza coordenadas e aplica
	var sprite_size = terrain_sprite.texture.get_size()
	var offset = sprite_size / 2.0
	
	var centered_polygon = PackedVector2Array()
	for point in polygons[0]:
		centered_polygon.append(point - offset)
	
	terrain_collision.polygon = centered_polygon
	
	print("🎨 [TERRAIN_RENDERER] Colisão gerada (", centered_polygon.size(), " pontos)")

func update_visual():
	"""Atualiza textura visual do terreno"""
	
	if not terrain_texture or not terrain_image:
		print("❌ [TERRAIN_RENDERER] Dados de textura não existem")
		return
	
	terrain_texture.update(terrain_image)
	print("🎨 [TERRAIN_RENDERER] Visual atualizado")

func update_collision():
	"""Atualiza apenas a colisão (otimização)"""
	generate_collision()

func update_all():
	"""Atualiza visual + colisão (método completo)"""
	update_visual()
	update_collision()

# ===== GETTERS PARA ACESSO AOS DADOS =====

func get_terrain_image() -> Image:
	return terrain_image

func get_terrain_bitmap() -> BitMap:
	return terrain_bitmap

func get_terrain_texture() -> ImageTexture:
	return terrain_texture

func get_terrain_size() -> Vector2:
	if terrain_image:
		return terrain_image.get_size()
	return Vector2.ZERO

# ===== MÉTODOS DE UTILIDADE =====

func is_initialized() -> bool:
	"""Verifica se renderer foi inicializado corretamente"""
	return terrain_sprite != null and terrain_collision != null and terrain_image != null

func get_stats() -> Dictionary:
	"""Retorna estatísticas do terreno para debug"""
	
	if not is_initialized():
		return {"status": "not_initialized"}
	
	return {
		"status": "ready",
		"image_size": terrain_image.get_size(),
		"bitmap_size": terrain_bitmap.get_size(),
		"collision_points": terrain_collision.polygon.size(),
		"texture_format": terrain_image.get_format()
	}
