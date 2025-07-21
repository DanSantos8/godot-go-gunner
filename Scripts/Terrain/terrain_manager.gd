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
	"""Gera CollisionPolygon2D do BitMap atual"""
	
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

# ===== CRATERAS PROCEDURAIS =====

func create_circular_crater(center: Vector2, hole_radius: float, burn_radius: float = 0):
	"""Cria cratera circular procedural com textura de explosão"""
	
	# Converte posição world para bitmap
	var sprite_size = terrain_image.get_size()
	var bitmap_center = center + sprite_size / 2.0
	
	# Valida se está dentro dos limites
	if bitmap_center.x < 0 or bitmap_center.x >= sprite_size.x or bitmap_center.y < 0 or bitmap_center.y >= sprite_size.y:
		return
	
	# Se não tem burn_radius, usa 150% do hole_radius
	if burn_radius <= 0:
		burn_radius = hole_radius * 1.5
	
	# Aplica cratera nos dados
	_apply_circular_crater_to_bitmap(bitmap_center, hole_radius, burn_radius)
	_apply_circular_crater_to_image(bitmap_center, hole_radius, burn_radius)
	
	# Atualiza visual e colisão
	_update_terrain()

func _apply_circular_crater_to_bitmap(center: Vector2, hole_radius: float, burn_radius: float):
	"""Remove área circular do bitmap (para colisão)"""
	
	var bitmap_size = terrain_bitmap.get_size()
	
	# Calcula área de processamento otimizada
	var min_x = max(0, int(center.x - burn_radius))
	var max_x = min(bitmap_size.x, int(center.x + burn_radius))
	var min_y = max(0, int(center.y - burn_radius))
	var max_y = min(bitmap_size.y, int(center.y + burn_radius))
	
	# Remove pixels dentro do hole_radius
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var distance = Vector2(x, y).distance_to(center)
			
			# Remove colisão apenas no buraco central
			if distance <= hole_radius:
				terrain_bitmap.set_bit(x, y, false)

func _apply_circular_crater_to_image(center: Vector2, hole_radius: float, burn_radius: float):
	"""Aplica efeito visual circular na imagem"""
	
	var image_size = terrain_image.get_size()
	
	# Calcula área de processamento otimizada
	var min_x = max(0, int(center.x - burn_radius))
	var max_x = min(image_size.x, int(center.x + burn_radius))
	var min_y = max(0, int(center.y - burn_radius))
	var max_y = min(image_size.y, int(center.y + burn_radius))
	
	# Cores da cratera
	var burn_color = Color.GREEN  # Placeholder verde
	var transparent = Color.TRANSPARENT
	
	# Aplica efeito por zona
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var distance = Vector2(x, y).distance_to(center)
			
			if distance <= hole_radius:
				# Zona do buraco: Transparente
				terrain_image.set_pixel(x, y, transparent)
			elif distance <= burn_radius:
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

func _on_projectile_collision(collision_position: Vector2):
	"""Cria cratera quando projétil colide com terreno"""
	
	var local_position = to_local(collision_position)
	
	# Cratera menor: hole=15px, burn=25px
	crater_queue.add_crater_request(local_position, 15.0, 25.0)

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
