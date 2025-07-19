# Scripts/Terrain/terrain_bitmap.gd
extends StaticBody2D

@onready var terrain_sprite = $TerrainSprite
@onready var terrain_collision = $TerrainCollision
@onready var bitmap_converter = preload("res://Scripts/Terrain/bitmap_converter.gd")
@onready var collision_generator = preload("res://Scripts/Terrain/collision_generator.gd")

func _ready():
	test_bitmap_converter()

func test_bitmap_converter():
	print("🧪 [TEST] Iniciando teste do BitmapConverter...")
	
	var texture = terrain_sprite.texture
	var bitmap = bitmap_converter.texture_to_bitmap(texture)
	
	if bitmap:
		var size = bitmap.get_size()
		print("✅ [TEST] BitMap criado! Tamanho: ", size.x, "x", size.y)
		test_sample_pixels(bitmap, size)
		
		# Testa collision generator
		test_collision_generator(bitmap)
	else:
		print("❌ [TEST] Falha ao criar BitMap!")

func test_sample_pixels(bitmap: BitMap, size: Vector2i):
	print("🔍 [TEST] Testando pixels de amostra...")
	
	# Testa vários pontos para entender o padrão
	var test_points = [
		Vector2i(0, 0),                    # Canto superior esquerdo
		Vector2i(size.x-1, 0),            # Canto superior direito  
		Vector2i(0, size.y-1),            # Canto inferior esquerdo
		Vector2i(size.x-1, size.y-1),     # Canto inferior direito
		Vector2i(size.x/2, size.y/2),     # Centro
		Vector2i(size.x/2, size.y-50),    # Meio, mais acima
		Vector2i(size.x/2, size.y-100),   # Meio, bem acima
	]
	
	for point in test_points:
		var is_solid = bitmap.get_bit(point.x, point.y)
		print("  Pixel (", point.x, ",", point.y, "): ", "SÓLIDO" if is_solid else "VAZIO")
	
	# Conta quantos pixels sólidos temos no total
	var solid_count = 0
	var total_pixels = size.x * size.y
	
	for y in range(size.y):
		for x in range(size.x):
			if bitmap.get_bit(x, y):
				solid_count += 1
	
	var percentage = (solid_count * 100.0) / total_pixels
	print("📊 [TEST] Pixels sólidos: ", solid_count, "/", total_pixels, " (", "%.1f" % percentage, "%)")

func test_collision_generator(bitmap: BitMap):
	print("🧪 [TEST] Testando CollisionGenerator...")
	
	var polygon_points = collision_generator.bitmap_to_collision_polygon(bitmap, true)  # true = sprite centralizado
	
	if polygon_points.size() > 0:
		print("✅ [TEST] Polygon gerado com ", polygon_points.size(), " pontos")
		terrain_collision.polygon = polygon_points
		print("✅ [TEST] Collision aplicada ao node!")
		
		# NOVO: Cria marcadores visuais nos pontos da collision
		create_visual_markers(polygon_points)
		
		test_destruction_system(bitmap)
		
	else:
		print("❌ [TEST] Falha ao gerar polygon!")

func create_visual_markers(points: PackedVector2Array):
	print("🎨 [VISUAL] Criando marcadores visuais...")
	
	# Remove marcadores antigos se existirem
	for child in get_children():
		if child.name.begins_with("Marker"):
			child.queue_free()
	
	# Cria marcadores vermelhos a cada 20 pontos
	for i in range(0, points.size(), 20):
		var marker = ColorRect.new()
		marker.name = "Marker" + str(i)
		marker.size = Vector2(4, 4)
		marker.color = Color.RED
		marker.position = points[i] - Vector2(2, 2)  # Centraliza o marcador
		add_child(marker)
	
	print("🎨 [VISUAL] Criados ", points.size() / 20, " marcadores vermelhos")

func test_destruction_system(original_bitmap: BitMap):
	print("🧪 [TEST] Testando DestructionSystem...")
	
	# Importa o destruction system
	var destruction_system = preload("res://Scripts/Terrain/destruction_system.gd")
	
	# Aplica destruição no centro do terreno (VISUAL + COLLISION)
	var center = Vector2(576, 200)  # Centro aproximado
	var radius = 50.0
	
	var destroyed_bitmap = destruction_system.apply_circular_brush_with_visual(original_bitmap, terrain_sprite, center, radius)
	
	if destroyed_bitmap:
		# Regenera collision com terreno destruído
		var new_polygon = collision_generator.bitmap_to_collision_polygon(destroyed_bitmap, true)
		terrain_collision.polygon = new_polygon
		
		# Remove marcadores antigos e cria novos
		create_visual_markers(new_polygon)
		
		print("✅ [TEST] Destruição VISUAL + COLLISION aplicada!")
	else:
		print("❌ [TEST] Falha na destruição!")
