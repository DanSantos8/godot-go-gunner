# Scripts/Terrain/destruction_system.gd
extends Node

static func apply_circular_brush(bitmap: BitMap, center_pos: Vector2, radius: float) -> BitMap:
	if not bitmap:
		print("❌ [DESTRUCTION] BitMap é null!")
		return null
	
	var size = bitmap.get_size()
	print("🧨 [DESTRUCTION] Aplicando brush circular em (", center_pos.x, ",", center_pos.y, ") com raio ", radius)
	
	# Cria uma nova instância do bitmap para modificar
	var new_bitmap = BitMap.new()
	new_bitmap.create(size)
	
	# Copia o bitmap original
	for y in range(size.y):
		for x in range(size.x):
			new_bitmap.set_bit(x, y, bitmap.get_bit(x, y))
	
	# Aplica destruição circular
	var radius_squared = radius * radius
	var pixels_destroyed = 0
	
	for y in range(max(0, center_pos.y - radius), min(size.y, center_pos.y + radius + 1)):
		for x in range(max(0, center_pos.x - radius), min(size.x, center_pos.x + radius + 1)):
			# Calcula distância do centro
			var distance_squared = (x - center_pos.x) * (x - center_pos.x) + (y - center_pos.y) * (y - center_pos.y)
			
			# Se está dentro do círculo, apaga (marca como falso)
			if distance_squared <= radius_squared:
				if new_bitmap.get_bit(x, y):  # Só conta se estava sólido antes
					pixels_destroyed += 1
				new_bitmap.set_bit(x, y, false)
	
	print("✅ [DESTRUCTION] Brush aplicado! ", pixels_destroyed, " pixels destruídos")
	return new_bitmap

static func apply_circular_brush_with_visual(bitmap: BitMap, sprite: Sprite2D, center_pos: Vector2, radius: float) -> BitMap:
	"""Aplica destruição tanto no BitMap quanto na textura visual"""
	if not bitmap or not sprite:
		print("❌ [DESTRUCTION] BitMap ou Sprite é null!")
		return null
	
	var size = bitmap.get_size()
	print("🎨 [DESTRUCTION] Aplicando destruição visual + collision em (", center_pos.x, ",", center_pos.y, ") com raio ", radius)
	
	# 1. Modifica o BitMap (para collision)
	var new_bitmap = apply_circular_brush(bitmap, center_pos, radius)
	
	# 2. Modifica a textura visual (para aparecer na tela)
	apply_visual_destruction(sprite, center_pos, radius)
	
	return new_bitmap

static func apply_visual_destruction(sprite: Sprite2D, center_pos: Vector2, radius: float):
	"""Aplica buraco visual na textura do sprite"""
	var texture = sprite.texture
	if not texture:
		print("❌ [VISUAL_DESTRUCTION] Sprite não tem texture!")
		return
	
	# Extrai a imagem da texture
	var image: Image
	if texture is ImageTexture:
		image = texture.get_image()
	elif texture is CompressedTexture2D:
		image = texture.get_image()
	else:
		print("❌ [VISUAL_DESTRUCTION] Tipo de texture não suportado!")
		return
	
	# Cria cópia da imagem para modificar
	var new_image = image.duplicate()
	var radius_squared = radius * radius
	
	# Aplica destruição visual (pinta transparente)
	for y in range(max(0, center_pos.y - radius), min(new_image.get_height(), center_pos.y + radius + 1)):
		for x in range(max(0, center_pos.x - radius), min(new_image.get_width(), center_pos.x + radius + 1)):
			var distance_squared = (x - center_pos.x) * (x - center_pos.x) + (y - center_pos.y) * (y - center_pos.y)
			
			if distance_squared <= radius_squared:
				# Pinta pixel como transparente
				new_image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Cria nova ImageTexture com a imagem modificada
	var new_texture = ImageTexture.new()
	new_texture.set_image(new_image)
	
	# Aplica a nova texture ao sprite
	sprite.texture = new_texture
	
	print("✅ [VISUAL_DESTRUCTION] Buraco visual aplicado!")

static func apply_destruction_at_world_pos(bitmap: BitMap, sprite: Sprite2D, world_pos: Vector2, radius: float) -> BitMap:
	"""Converte posição mundial para coordenadas locais do bitmap e aplica destruição"""
	# Converte posição mundial para coordenadas locais do bitmap
	var sprite_pos = sprite.global_position
	var sprite_size = sprite.texture.get_size()
	
	# Calcula posição relativa ao sprite (considerando que sprite está centralizado)
	var local_pos = world_pos - sprite_pos + Vector2(sprite_size.x / 2, sprite_size.y / 2)
	
	print("🎯 [DESTRUCTION] Convertendo posição mundial ", world_pos, " para local ", local_pos)
	
	return apply_circular_brush(bitmap, local_pos, radius)

static func apply_rectangular_brush(bitmap: BitMap, center_pos: Vector2, width: float, height: float) -> BitMap:
	"""Aplica destruição retangular - útil para armas como drill"""
	if not bitmap:
		print("❌ [DESTRUCTION] BitMap é null!")
		return null
	
	var size = bitmap.get_size()
	print("🧨 [DESTRUCTION] Aplicando brush retangular ", width, "x", height, " em (", center_pos.x, ",", center_pos.y, ")")
	
	# Cria uma nova instância do bitmap para modificar
	var new_bitmap = BitMap.new()
	new_bitmap.create(size)
	
	# Copia o bitmap original
	for y in range(size.y):
		for x in range(size.x):
			new_bitmap.set_bit(x, y, bitmap.get_bit(x, y))
	
	# Calcula limites do retângulo
	var half_width = width / 2
	var half_height = height / 2
	var left = max(0, center_pos.x - half_width)
	var right = min(size.x, center_pos.x + half_width)
	var top = max(0, center_pos.y - half_height)
	var bottom = min(size.y, center_pos.y + half_height)
	
	var pixels_destroyed = 0
	
	# Aplica destruição retangular
	for y in range(top, bottom):
		for x in range(left, right):
			if new_bitmap.get_bit(x, y):
				pixels_destroyed += 1
			new_bitmap.set_bit(x, y, false)
	
	print("✅ [DESTRUCTION] Brush retangular aplicado! ", pixels_destroyed, " pixels destruídos")
	return new_bitmap

static func create_destruction_preview(center_pos: Vector2, radius: float, color: Color = Color.RED) -> PackedVector2Array:
	"""Cria array de pontos para preview visual da área de destruição"""
	var points = PackedVector2Array()
	var segments = 32  # Resolução do círculo
	
	for i in range(segments + 1):
		var angle = (i * 2.0 * PI) / segments
		var x = center_pos.x + cos(angle) * radius
		var y = center_pos.y + sin(angle) * radius
		points.append(Vector2(x, y))
	
	return points
