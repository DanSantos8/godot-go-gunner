# Scripts/Terrain/crater_processor.gd
class_name CraterProcessor extends RefCounted

# Resultado do processamento
class ProcessingResult:
	var pixels_processed: int = 0
	var pixels_skipped: int = 0
	var pixels_removed: int = 0
	var processing_time_ms: int = 0

func process_crater_masks(terrain_image: Image, terrain_bitmap: BitMap, position: Vector2, hole_mask: Image, texture_mask: Image) -> ProcessingResult:
	"""Processa máscaras de cratera e retorna resultado"""
	
	var result = ProcessingResult.new()
	var start_time = Time.get_ticks_msec()
	
	print("🚀 [CRATER_PROCESSOR] Processando crateras...")
	
	# Calcula área de processamento otimizada
	var sprite_size = terrain_image.get_size()
	var bitmap_position = position + sprite_size / 2.0
	
	var max_mask_size = Vector2(
		max(hole_mask.get_size().x, texture_mask.get_size().x),
		max(hole_mask.get_size().y, texture_mask.get_size().y)
	)
	
	var processing_area = _calculate_processing_area(bitmap_position, max_mask_size, sprite_size)
	
	# Aplica máscaras
	var texture_result = _apply_texture_mask(terrain_image, bitmap_position, texture_mask, processing_area)
	var hole_result = _apply_hole_mask(terrain_image, terrain_bitmap, bitmap_position, hole_mask, processing_area)
	
	# Combina resultados
	result.pixels_processed = texture_result.pixels_processed
	result.pixels_skipped = texture_result.pixels_skipped
	result.pixels_removed = hole_result.pixels_removed
	result.processing_time_ms = Time.get_ticks_msec() - start_time
	
	print("✅ [CRATER_PROCESSOR] Processamento concluído em ", result.processing_time_ms, "ms")
	
	return result

func _calculate_processing_area(center_position: Vector2, mask_size: Vector2, terrain_size: Vector2) -> Rect2i:
	"""Calcula área mínima necessária para processamento"""
	
	# Área ao redor do centro
	var half_size = mask_size / 2
	var start_x = max(0, int(center_position.x - half_size.x))
	var start_y = max(0, int(center_position.y - half_size.y))
	var end_x = min(terrain_size.x, int(center_position.x + half_size.x))
	var end_y = min(terrain_size.y, int(center_position.y + half_size.y))
	
	var area = Rect2i(start_x, start_y, end_x - start_x, end_y - start_y)
	print("📐 [CRATER_PROCESSOR] Área de processamento: ", area, " (", area.size.x * area.size.y, " pixels)")
	
	return area

func _apply_texture_mask(terrain_image: Image, center_position: Vector2, texture_mask: Image, processing_area: Rect2i) -> ProcessingResult:
	"""Aplica textura de fundo com área limitada - SÓ onde já havia terreno"""
	
	var result = ProcessingResult.new()
	var mask_size = texture_mask.get_size()
	var mask_start = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🎨 [CRATER_PROCESSOR] Aplicando textura na área ", processing_area.size)
	
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
				# Só aplica SE já havia terreno ali antes
				var existing_pixel = terrain_image.get_pixel(terrain_x, terrain_y)
				
				if existing_pixel.a > 0.1:  # Se não é transparente/ar
					terrain_image.set_pixel(terrain_x, terrain_y, mask_pixel)
					result.pixels_processed += 1
				else:
					result.pixels_skipped += 1  # Pulou porque era ar/transparente
	
	print("✅ [CRATER_PROCESSOR] Textura aplicada: ", result.pixels_processed, " pixels (", result.pixels_skipped, " pulados por serem ar)")
	return result

func _apply_hole_mask(terrain_image: Image, terrain_bitmap: BitMap, center_position: Vector2, hole_mask: Image, processing_area: Rect2i) -> ProcessingResult:
	"""Remove buraco com área limitada"""
	
	var result = ProcessingResult.new()
	var mask_size = hole_mask.get_size()
	var mask_start = Vector2(
		center_position.x - mask_size.x / 2,
		center_position.y - mask_size.y / 2
	)
	
	print("🕳️ [CRATER_PROCESSOR] Removendo buraco na área ", processing_area.size)
	
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
				result.pixels_removed += 1
	
	print("✅ [CRATER_PROCESSOR] Buraco removido: ", result.pixels_removed, " pixels")
	return result

func _is_black_pixel(pixel: Color) -> bool:
	"""Verifica se pixel é considerado preto (para remoção)"""
	
	var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
	return brightness < 0.2 and pixel.a > 0.5
