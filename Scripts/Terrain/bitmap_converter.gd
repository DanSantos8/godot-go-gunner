extends Node


static func texture_to_bitmap(texture: Texture2D) -> BitMap:
	if not texture:
		print("❌ [BITMAP_CONVERTER] Texture é null!")
		return null
	
	# Extrai Image independente do tipo de texture
	var image: Image
	
	if texture is ImageTexture:
		image = texture.get_image()
	elif texture is CompressedTexture2D:
		image = texture.get_image()
	else:
		print("❌ [BITMAP_CONVERTER] Tipo de texture não suportado: ", texture.get_class())
		return null
	
	if not image:
		print("❌ [BITMAP_CONVERTER] Não conseguiu extrair Image da texture!")
		return null
	
	# Cria BitMap com mesmo tamanho da imagem
	var bitmap = BitMap.new()
	var size = image.get_size()
	bitmap.create(size)
	
	print("🔧 [BITMAP_CONVERTER] Processando imagem ", size.x, "x", size.y)
	
	# Processa cada pixel
	for y in range(size.y):
		for x in range(size.x):
			var pixel = image.get_pixel(x, y)
			var alpha = pixel.a
			
			# Se alpha > threshold, marca como sólido
			var is_solid = alpha > get_alpha_threshold()
			bitmap.set_bit(x, y, is_solid)
	
	print("✅ [BITMAP_CONVERTER] BitMap criado com sucesso!")
	return bitmap
	
static func get_alpha_threshold(): 
	return 0.1
