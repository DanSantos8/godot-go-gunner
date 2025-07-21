# Scripts/Terrain/terrain_manager.gd - V4.0 (Crateras Procedurais)
class_name TerrainBitmap extends StaticBody2D

# Referencias de nodes
@onready var terrain_sprite: Sprite2D = $TerrainSprite
@onready var terrain_collision: CollisionPolygon2D = $TerrainCollision

# Dados do terreno
var terrain_bitmap: BitMap
var terrain_image: Image
var terrain_texture: ImageTexture

# ===== CRATER QUEUE =====
var crater_queue: CraterQueue

func _ready():
	# Conecta signal de colisão do projétil
	MessageBus.projectile_collided_with_terrain.connect(_on_projectile_collision)
	
	# Valida nodes filhos
	if not terrain_sprite or not terrain_collision:
		return
	
	# Inicializa crater queue
	crater_queue = CraterQueue.new()
	crater_queue.initialize(self)
	
	# Setup inicial do terreno
	_setup_terrain_from_texture()
	
	# 🧪 TESTE: Descomente para testar crateras
	# _test_procedural_craters()

func _setup_terrain_from_texture():
	"""Configura terreno inicial a partir da textura"""
	
	var source_texture = terrain_sprite.texture
	if not source_texture:
		return
	
	# Cria dados editáveis
	terrain_image = source_texture.get_image().duplicate()
	terrain_texture = ImageTexture.new()
	terrain_texture.set_image(terrain_image)
	terrain_sprite.texture = terrain_texture
	
	# Cria bitmap para colisão
	terrain_bitmap = BitMap.new()
	terrain_bitmap.create_from_image_alpha(terrain_image, 0.1)
	
	# Gera colisão inicial
	_generate_collision()

func _generate_collision():
	"""Gera CollisionPolygon2D do BitMap atual com suporte a múltiplas ilhas"""
	
	if not terrain_bitmap:
		return
	
	# Converte bitmap para polígonos
	var rect = Rect2(Vector2.ZERO, terrain_bitmap.get_size())
	var polygons = terrain_bitmap.opaque_to_polygons(rect, 2.0)
	
	if polygons.is_empty():
		return
	
	print("🏝️ [TERRAIN] Encontrados ", polygons.size(), " polígonos")
	
	# Remove colisões antigas
	_clear_existing_collisions()
	
	# Cria collision para cada polígono (ilha)
	var sprite_size = terrain_sprite.texture.get_size()
	var offset = sprite_size / 2.0
	
	for i in range(polygons.size()):
		var polygon_points = polygons[i]
		
		# Centraliza coordenadas
		var centered_polygon = PackedVector2Array()
		for point in polygon_points:
			centered_polygon.append(point - offset)
		
		if i == 0:
			# Primeiro polígono usa a CollisionPolygon2D existente
			terrain_collision.polygon = centered_polygon
		else:
			# Polígonos adicionais criam novas CollisionPolygon2D
			_create_additional_collision(centered_polygon, i)
	
	print("🎯 [TERRAIN] ", polygons.size(), " ilhas de colisão criadas")

func _clear_existing_collisions():
	"""Remove CollisionPolygon2D extras (mantém a primeira)"""
	
	# Remove collision shapes extras criadas anteriormente
	for child in get_children():
		if child is CollisionPolygon2D and child != terrain_collision:
			child.queue_free()

func _create_additional_collision(polygon_points: PackedVector2Array, index: int):
	"""Cria CollisionPolygon2D adicional para ilhas flutuantes"""
	
	var new_collision = CollisionPolygon2D.new()
	new_collision.name = "TerrainCollision_Island_" + str(index)
	new_collision.polygon = polygon_points
	
	add_child(new_collision)
	print("🏝️ [TERRAIN] Ilha ", index, " criada com ", polygon_points.size(), " pontos")

# ===== CRATERAS PROCEDURAIS =====

func create_elliptical_crater(center: Vector2, radius_x: float, radius_y: float, burn_multiplier: float = 1.5):
	"""Cria cratera elíptica/oval procedural"""
	
	# Converte posição world para bitmap
	var sprite_size = terrain_image.get_size()
	var bitmap_center = center + sprite_size / 2.0
	
	# Valida se está dentro dos limites
	if bitmap_center.x < 0 or bitmap_center.x >= sprite_size.x or bitmap_center.y < 0 or bitmap_center.y >= sprite_size.y:
		return
	
	# Calcula raios de queimadura
	var burn_radius_x = radius_x * burn_multiplier
	var burn_radius_y = radius_y * burn_multiplier
	
	# Aplica cratera nos dados
	_apply_elliptical_crater_to_bitmap(bitmap_center, radius_x, radius_y, burn_radius_x, burn_radius_y)
	_apply_elliptical_crater_to_image(bitmap_center, radius_x, radius_y, burn_radius_x, burn_radius_y)
	
	# Atualiza visual e colisão
	_update_terrain()

func create_circular_crater(center: Vector2, hole_radius: float, burn_radius: float = 0):
	"""Cria cratera circular (wrapper para elíptica)"""
	
	if burn_radius <= 0:
		burn_radius = hole_radius * 1.5
	
	# Converte círculo para elipse com raios iguais
	var burn_multiplier = burn_radius / hole_radius
	create_elliptical_crater(center, hole_radius, hole_radius, burn_multiplier)

func _apply_elliptical_crater_to_bitmap(center: Vector2, hole_rx: float, hole_ry: float, burn_rx: float, burn_ry: float):
	"""Remove área elíptica do bitmap (para colisão)"""
	
	var bitmap_size = terrain_bitmap.get_size()
	
	# Calcula área de processamento otimizada
	var min_x = max(0, int(center.x - burn_rx))
	var max_x = min(bitmap_size.x, int(center.x + burn_rx))
	var min_y = max(0, int(center.y - burn_ry))
	var max_y = min(bitmap_size.y, int(center.y + burn_ry))
	
	# Remove pixels dentro da elipse central
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			# Fórmula da elipse: (x-cx)²/rx² + (y-cy)²/ry² <= 1
			var dx = (x - center.x) / hole_rx
			var dy = (y - center.y) / hole_ry
			var ellipse_distance = dx * dx + dy * dy
			
			# Remove colisão se está dentro da elipse
			if ellipse_distance <= 1.0:
				terrain_bitmap.set_bit(x, y, false)

func _apply_elliptical_crater_to_image(center: Vector2, hole_rx: float, hole_ry: float, burn_rx: float, burn_ry: float):
	"""Aplica efeito visual elíptico na imagem"""
	
	var image_size = terrain_image.get_size()
	
	# Calcula área de processamento otimizada
	var min_x = max(0, int(center.x - burn_rx))
	var max_x = min(image_size.x, int(center.x + burn_rx))
	var min_y = max(0, int(center.y - burn_ry))
	var max_y = min(image_size.y, int(center.y + burn_ry))
	
	# Cores da cratera
	var burn_color = Color.GREEN  # Placeholder verde
	var transparent = Color.TRANSPARENT
	
	# Aplica efeito por zona elíptica
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			# Calcula distâncias elípticas
			var hole_dx = (x - center.x) / hole_rx
			var hole_dy = (y - center.y) / hole_ry
			var hole_distance = hole_dx * hole_dx + hole_dy * hole_dy
			
			var burn_dx = (x - center.x) / burn_rx
			var burn_dy = (y - center.y) / burn_ry
			var burn_distance = burn_dx * burn_dx + burn_dy * burn_dy
			
			if hole_distance <= 1.0:
				# Zona do buraco: Transparente
				terrain_image.set_pixel(x, y, transparent)
			elif burn_distance <= 1.0:
				# Zona de explosão: Verde (placeholder)
				var existing_pixel = terrain_image.get_pixel(x, y)
				if existing_pixel.a > 0.1:  # Só aplica onde já havia terreno
					terrain_image.set_pixel(x, y, burn_color)

func _update_terrain():
	"""Atualiza visual e colisão do terreno"""
	
	# Atualiza textura visual
	terrain_texture.update(terrain_image)
	
	# Regenera colisão (deferred para evitar physics flush)
	call_deferred("_generate_collision")

# ===== SIGNAL HANDLERS =====

func _on_projectile_collision(collision_position: Vector2, destruction_shape: DestructionShape = null):
	"""Cria cratera quando projétil colide com terreno"""
	
	var local_position = to_local(collision_position)
	
	# Usa DestructionShape ou fallback para valores padrão
	if destruction_shape:
		crater_queue.add_crater_request(local_position, destruction_shape)
	else:
		# Fallback para compatibilidade (caso não tenha shape)
		crater_queue.add_crater_request(local_position, 15.0, 15.0)

# ===== TESTE DE CRATERAS (COMENTADO) =====

# func _test_procedural_craters():
# 	"""Teste: Cria algumas crateras procedurais usando a CraterQueue"""
# 	
# 	await get_tree().create_timer(1.0).timeout
# 	
# 	# Crateras dentro da área visível do terreno
# 	crater_queue.add_crater_request(Vector2(-300, -50), 25.0, 40.0)
# 	crater_queue.add_crater_request(Vector2(300, -50), 35.0, 55.0)
# 	crater_queue.add_crater_request(Vector2(0, 50), 50.0, 75.0)

# func _on_test_finished():
# 	"""Chamado quando todas as crateras de teste foram processadas"""
# 	pass
