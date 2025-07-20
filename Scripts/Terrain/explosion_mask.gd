# Scripts/explosion_mask.gd
class_name ExplosionMask extends Node

# Configurações
@export var mask_texture_path: String = "res://path/to/explosion_mask.png"
@export var color_tolerance: float = 0.3

# Cores para detectar
var red_color = Color.RED      # Destruição
var yellow_color = Color.YELLOW # Efeitos

func apply_mask_at_position(terrain: TerrainBitmap, world_position: Vector2):
	"""Aplica máscara colorida no terreno"""
	
	# Carrega a máscara
	var mask_texture = load(mask_texture_path) as Texture2D
	if not mask_texture:
		print("❌ [EXPLOSION_MASK] Máscara não encontrada: ", mask_texture_path)
		return
	
	var mask_image = mask_texture.get_image()
	var mask_size = mask_image.get_size()
	
	print("✅ [EXPLOSION_MASK] Aplicando máscara ", mask_size, " em ", world_position)
	
	# Converte posição para coordenadas do bitmap
	var sprite_size = terrain.terrain_sprite.texture.get_size()
	var bitmap_position = world_position + sprite_size / 2.0
	var start_pos = bitmap_position - mask_size / 2.0
	
	# Aplica a máscara
	_process_mask_pixels(terrain, mask_image, start_pos)
	
	# Regenera colisão do terreno
	terrain._generate_collision()

func _process_mask_pixels(terrain: TerrainBitmap, mask_image: Image, start_position: Vector2):
	"""Processa cada pixel da máscara"""
	
	var mask_size = mask_image.get_size()
	var terrain_size = terrain.terrain_bitmap.get_size()
	
	var destruction_count = 0
	var effect_count = 0
	
	# Analisa cada pixel da máscara
	for y in range(mask_size.y):
		for x in range(mask_size.x):
			var mask_pixel = mask_image.get_pixel(x, y)
			
			# Ignora pixels transparentes
			if mask_pixel.a < 0.1:
				continue
			
			# Calcula posição no terreno
			var terrain_x = int(start_position.x + x)
			var terrain_y = int(start_position.y + y)
			
			# Verifica limites
			if terrain_x < 0 or terrain_x >= terrain_size.x or terrain_y < 0 or terrain_y >= terrain_size.y:
				continue
			
			# Detecta cor e aplica efeito
			if _is_color_similar(mask_pixel, red_color, color_tolerance):
				# VERMELHO = Destruir
				_apply_destruction(terrain, terrain_x, terrain_y)
				destruction_count += 1
				
			elif _is_color_similar(mask_pixel, yellow_color, color_tolerance):
				# AMARELO = Efeito visual
				_apply_visual_effect(terrain, terrain_x, terrain_y)
				effect_count += 1
	
	# Atualiza textura
	terrain.terrain_texture.update(terrain.terrain_image)
	
	print("✅ [EXPLOSION_MASK] Pixels destruídos: ", destruction_count, " | Efeitos: ", effect_count)

func _apply_destruction(terrain: TerrainBitmap, x: int, y: int):
	"""Aplica destruição (vermelho)"""
	terrain.terrain_bitmap.set_bit(x, y, false)
	terrain.terrain_image.set_pixel(x, y, Color.TRANSPARENT)

func _apply_visual_effect(terrain: TerrainBitmap, x: int, y: int):
	"""Aplica efeito visual (amarelo)"""
	# Por enquanto, cor marrom (poeira)
	# Só aplica se ainda tem terreno nessa posição
	if terrain.terrain_bitmap.get_bit(x, y):
		terrain.terrain_image.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1.0))  # Marrom

func _is_color_similar(color1: Color, color2: Color, tolerance: float) -> bool:
	"""Verifica similaridade de cores"""
	var diff = abs(color1.r - color2.r) + abs(color1.g - color2.g) + abs(color1.b - color2.b)
	return diff <= tolerance
