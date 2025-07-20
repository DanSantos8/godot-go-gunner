# Scripts/crater_config.gd
class_name CraterConfig extends Resource

# Tamanho da cratera (largura x altura para efeito oval)
@export var crater_size: Vector2 = Vector2(80, 40)  # Largura maior = achatamento

# Raios de efeito
@export var inner_radius: float = 0.3   # Até onde é buraco total (0-1)
@export var outer_radius: float = 1.0   # Até onde vai o efeito suave (0-1)

# Curva de transição
@export var falloff_curve: float = 2.0  # 1.0 = linear, 2.0 = suave, 4.0 = bem suave

# Configurações visuais
@export var opacity_multiplier: float = 0.8  # Intensidade da transparência

func _init():
	# Valores padrão para uma cratera suave e achatada
	crater_size = Vector2(80, 40)
	inner_radius = 0.3
	outer_radius = 1.0
	falloff_curve = 2.0
	opacity_multiplier = 0.8

# ===== PRESETS =====

static func get_default_crater() -> CraterConfig:
	"""Cratera padrão - achatada e suave"""
	var config = CraterConfig.new()
	config.crater_size = Vector2(80, 40)
	config.inner_radius = 0.3
	config.outer_radius = 1.0
	config.falloff_curve = 2.0
	return config

static func get_small_crater() -> CraterConfig:
	"""Cratera pequena para projéteis leves"""
	var config = CraterConfig.new()
	config.crater_size = Vector2(50, 25)
	config.inner_radius = 0.4
	config.outer_radius = 1.0
	config.falloff_curve = 1.5
	return config

static func get_large_crater() -> CraterConfig:
	"""Cratera grande para explosivos"""
	var config = CraterConfig.new()
	config.crater_size = Vector2(120, 60)
	config.inner_radius = 0.2
	config.outer_radius = 1.0
	config.falloff_curve = 3.0
	return config
