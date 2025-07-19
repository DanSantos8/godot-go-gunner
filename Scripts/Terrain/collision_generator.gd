# Scripts/Terrain/collision_generator.gd
extends Node

static func bitmap_to_collision_polygon(bitmap: BitMap, sprite_centered: bool = true) -> PackedVector2Array:
	if not bitmap:
		print("❌ [COLLISION_GENERATOR] BitMap é null!")
		return PackedVector2Array()
	
	var size = bitmap.get_size()
	print("🔧 [COLLISION_GENERATOR] Gerando collision para bitmap ", size.x, "x", size.y)
	
	# Encontra contorno do terreno
	var outline_points = generate_collision_outline(bitmap)
	
	if outline_points.size() < 3:
		print("❌ [COLLISION_GENERATOR] Poucos pontos encontrados: ", outline_points.size())
		return PackedVector2Array()
	
	# NOVO: Ajusta offset se sprite estiver centralizado
	if sprite_centered:
		var offset = Vector2(-size.x / 2, -size.y / 2)
		print("🔧 [COLLISION_GENERATOR] Aplicando offset para sprite centralizado: ", offset)
		
		for i in range(outline_points.size()):
			outline_points[i] += offset
	
	print("✅ [COLLISION_GENERATOR] Outline gerado com ", outline_points.size(), " pontos")
	return outline_points

static func generate_collision_outline(bitmap: BitMap) -> PackedVector2Array:
	var size = bitmap.get_size()
	var points = PackedVector2Array()
	
	print("🔍 [COLLISION_GENERATOR] Gerando outline simples...")
	
	var step = 4  # Resolução do outline
	
	# 1. Coleta pontos do topo (esquerda para direita)
	for x in range(0, size.x, step):
		var top_y = find_terrain_top(bitmap, x, size.y)
		if top_y >= 0:
			points.append(Vector2(x, top_y))
	
	# 2. Se temos pontos, fecha o polygon pela base
	if points.size() >= 2:
		var last_point = points[-1]
		var first_point = points[0]
		
		# Adiciona cantos da base para fechar
		points.append(Vector2(last_point.x, size.y))  # Canto inferior direito
		points.append(Vector2(first_point.x, size.y)) # Canto inferior esquerdo
		
		print("🔍 [COLLISION_GENERATOR] Outline fechado com ", points.size(), " pontos")
		print("🔍 [COLLISION_GENERATOR] Primeiro: ", first_point, " | Último: ", last_point)
	else:
		print("❌ [COLLISION_GENERATOR] Poucos pontos encontrados!")
	
	return points

static func find_terrain_top(bitmap: BitMap, x: int, max_y: int) -> int:
	# Procura de cima para baixo o primeiro pixel sólido
	for y in range(max_y):
		if bitmap.get_bit(x, y):
			return y
	
	return -1  # Não encontrou terreno nesta coluna
