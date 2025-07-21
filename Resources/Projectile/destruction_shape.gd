class_name DestructionShape extends Resource

enum ShapeType {
	CIRCLE,
	OVAL,
	RECTANGLE
}

@export var shape_type: ShapeType = ShapeType.CIRCLE
@export var size: Vector2 = Vector2(15, 15)  # width, height
@export var burn_multiplier: float = 1.5

# ===== PRESETS =====

static func create_small_circle() -> DestructionShape:
	var shape = DestructionShape.new()
	shape.shape_type = ShapeType.CIRCLE
	shape.size = Vector2(12, 12)
	shape.burn_multiplier = 1.4
	return shape

static func create_medium_oval() -> DestructionShape:
	var shape = DestructionShape.new()
	shape.shape_type = ShapeType.OVAL
	shape.size = Vector2(20, 12)  # Achatado
	shape.burn_multiplier = 1.5
	return shape

static func create_large_explosion() -> DestructionShape:
	var shape = DestructionShape.new()
	shape.shape_type = ShapeType.CIRCLE
	shape.size = Vector2(30, 30)
	shape.burn_multiplier = 2.0
	return shape

# ===== HELPER METHODS =====

func get_effective_burn_size() -> Vector2:
	"""Retorna tamanho da zona de queimadura"""
	return size * burn_multiplier

func is_circular() -> bool:
	"""Verifica se é circular (width == height)"""
	return abs(size.x - size.y) < 0.1
