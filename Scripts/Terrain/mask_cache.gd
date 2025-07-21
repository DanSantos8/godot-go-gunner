# Scripts/Terrain/mask_cache.gd
class_name MaskCache extends RefCounted

# Cache interno
var _cache: Dictionary = {}

func _init():
	print("💾 [MASK_CACHE] Inicializando cache...")
	preload_common_masks()

func preload_common_masks():
	"""Pre-carrega máscaras comuns no cache"""
	
	print("🔄 [MASK_CACHE] Pre-carregando máscaras...")
	
	var common_masks = [
		"res://Sprites/Craters/hole-crater.png",
		"res://Sprites/Craters/grass-hole.png"
	]
	
	for mask_path in common_masks:
		load_mask_image(mask_path)
	
	print("✅ [MASK_CACHE] Cache inicializado com ", _cache.size(), " máscaras")

func load_mask_image(path: String) -> Image:
	"""Carrega máscara com cache"""
	
	# Se já está no cache, retorna
	if _cache.has(path):
		return _cache[path]
	
	# Carrega e valida
	if not ResourceLoader.exists(path):
		print("❌ [MASK_CACHE] Arquivo não encontrado: ", path)
		return null
	
	var texture = load(path) as Texture2D
	if not texture:
		print("❌ [MASK_CACHE] Erro ao carregar textura: ", path)
		return null
	
	var image = texture.get_image()
	if not image:
		print("❌ [MASK_CACHE] Erro ao extrair imagem: ", path)
		return null
	
	# Adiciona ao cache
	_cache[path] = image
	print("💾 [MASK_CACHE] Máscara armazenada no cache: ", path, " (", image.get_size(), ")")
	
	return image

func get_cache_size() -> int:
	"""Retorna tamanho do cache"""
	return _cache.size()

func clear_cache():
	"""Limpa o cache"""
	_cache.clear()
	print("🧹 [MASK_CACHE] Cache limpo")

func has_cached(path: String) -> bool:
	"""Verifica se máscara está no cache"""
	return _cache.has(path)
