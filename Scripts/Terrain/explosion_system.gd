# Scripts/explosion_system.gd
class_name ExplosionSystem extends Node

# Referência ao terreno
var terrain_bitmap: TerrainBitmap

func _ready():
	print("💥 [EXPLOSION_SYSTEM] Inicializando...")
	
	# Aguarda 1 frame para garantir que terreno foi criado
	await get_tree().process_frame
	
	# Busca o terreno na cena
	_find_terrain()
	
	# Cria cratera de teste
	if terrain_bitmap:
		_create_test_crater()

func _find_terrain():
	"""Encontra o TerrainBitmap na cena"""
	
	# Busca por TerrainBitmap na cena atual
	var scene_root = get_tree().current_scene
	terrain_bitmap = _search_for_terrain(scene_root)
	
	if terrain_bitmap:
		print("✅ [EXPLOSION_SYSTEM] Terreno encontrado!")
	else:
		print("❌ [EXPLOSION_SYSTEM] Terreno não encontrado!")

func _search_for_terrain(node: Node) -> TerrainBitmap:
	"""Busca recursiva por TerrainBitmap"""
	
	if node is TerrainBitmap:
		return node
	
	for child in node.get_children():
		var result = _search_for_terrain(child)
		if result:
			return result
	
	return null

func _create_test_crater():
	"""Cria uma cratera circular de teste"""
	
	print("🕳️ [EXPLOSION_SYSTEM] Criando cratera de teste...")
	
	# Posição no centro do terreno
	var crater_position = Vector2(200, -50)  # Um pouco à direita do centro
	var crater_radius = 40.0
	
	# Cria a cratera
	create_circular_crater(crater_position, crater_radius)

func create_circular_crater(position: Vector2, radius: float):
	"""Cria uma cratera circular no terreno"""
	
	if not terrain_bitmap or not terrain_bitmap.terrain_bitmap:
		print("❌ [EXPLOSION_SYSTEM] Terreno não disponível!")
		return
	
	print("💥 [EXPLOSION_SYSTEM] Criando cratera em ", position, " com raio ", radius)
	
	# Converte posição world para coordenadas do bitmap
	var terrain_size = terrain_bitmap.terrain_bitmap.get_size()
	var sprite_size = terrain_bitmap.terrain_sprite.texture.get_size()
	
	# Centraliza a posição (sprite está centralizado)
	var bitmap_position = position + sprite_size / 2.0
	
	# Cria bitmap circular para a cratera
	var crater_bitmap = _create_circular_bitmap(bitmap_position, radius, terrain_size)
	
	# Remove a área do terreno
	_subtract_from_terrain(crater_bitmap)
	
	# Regenera a colisão
	terrain_bitmap._generate_collision()

func _create_circular_bitmap(center: Vector2, radius: float, bitmap_size: Vector2) -> BitMap:
	"""Cria um BitMap circular"""
	
	var crater_bitmap = BitMap.new()
	crater_bitmap.create(bitmap_size)
	
	# Preenche o círculo
	for y in range(max(0, center.y - radius), min(bitmap_size.y, center.y + radius)):
		for x in range(max(0, center.x - radius), min(bitmap_size.x, center.x + radius)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				crater_bitmap.set_bit(x, y, true)
	
	return crater_bitmap

func _subtract_from_terrain(crater_bitmap: BitMap):
	"""Remove área da cratera do terreno"""
	
	var terrain_size = terrain_bitmap.terrain_bitmap.get_size()
	
	# Subtrai bit por bit
	for y in range(terrain_size.y):
		for x in range(terrain_size.x):
			if crater_bitmap.get_bit(x, y):
				terrain_bitmap.terrain_bitmap.set_bit(x, y, false)
	
	print("✅ [EXPLOSION_SYSTEM] Cratera removida do terreno!")

# ===== API PÚBLICA =====

func explode_at_position(world_position: Vector2, radius: float = 30.0):
	"""API para criar explosão em posição específica"""
	
	create_circular_crater(world_position, radius)
	print("💥 [EXPLOSION_SYSTEM] Explosão em ", world_position)
