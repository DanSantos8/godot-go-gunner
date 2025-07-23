# Scripts/TerrainV2/shape_processor.gd
class_name ShapeProcessor extends RefCounted

func apply_shape_destruction(terrain_image: Image, terrain_bitmap: BitMap, position: Vector2, explosion_data: Dictionary) -> int:
	"""Apply shape-based destruction to terrain"""
	
	var shape_type = explosion_data.get("shape_type", "")
	var shape_data = explosion_data.get("shape_data", {})
	
	print("🔍 [SHAPE_PROCESSOR] Processing shape: ", shape_type, " with data: ", shape_data)
	
	match shape_type:
		"CircleShape2D":
			return _apply_circle_destruction(terrain_image, terrain_bitmap, position, shape_data)
		"RectangleShape2D":
			print("⚠️ [SHAPE_PROCESSOR] RectangleShape2D not implemented yet")
			return 0
		_:
			print("❌ [SHAPE_PROCESSOR] Unknown shape type: ", shape_type)
			return 0

func _apply_circle_destruction(terrain_image: Image, terrain_bitmap: BitMap, center: Vector2, shape_data: Dictionary) -> int:
	"""Remove circular area from terrain"""
	
	var radius = shape_data.get("radius", 50.0)
	var pixels_removed = 0
	
	print("⭕ [SHAPE_PROCESSOR] Applying circle destruction - radius: ", radius, " at: ", center)
	
	# Calculate bounding box for optimization
	var min_x = max(0, int(center.x - radius))
	var max_x = min(terrain_image.get_width(), int(center.x + radius))
	var min_y = max(0, int(center.y - radius))
	var max_y = min(terrain_image.get_height(), int(center.y + radius))
	
	print("📐 [SHAPE_PROCESSOR] Processing area: ", Vector2(min_x, min_y), " to ", Vector2(max_x, max_y))
	
	# Remove pixels within circle
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var distance = Vector2(x, y).distance_to(center)
			
			if distance <= radius:
				# Check if pixel was solid before removing
				var was_solid = terrain_bitmap.get_bit(x, y)
				
				if was_solid:
					# Remove from visual (image)
					terrain_image.set_pixel(x, y, Color.TRANSPARENT)
					
					# Remove from collision (bitmap)
					terrain_bitmap.set_bit(x, y, false)
					
					pixels_removed += 1
	
	print("✅ [SHAPE_PROCESSOR] Circle destruction complete - ", pixels_removed, " pixels removed")
	return pixels_removed

func _apply_rectangle_destruction(terrain_image: Image, terrain_bitmap: BitMap, center: Vector2, shape_data: Dictionary) -> int:
	"""Remove rectangular area from terrain (TODO: Future implementation)"""
	
	var size = shape_data.get("size", Vector2(50, 50))
	var pixels_removed = 0
	
	print("🔲 [SHAPE_PROCESSOR] Rectangle destruction not implemented yet")
	# TODO: Implement rectangle destruction similar to circle
	
	return pixels_removed

# ===== UTILITY METHODS =====

func get_shape_bounds(center: Vector2, explosion_data: Dictionary) -> Rect2:
	"""Get bounding rectangle for shape (useful for optimizations)"""
	
	var shape_type = explosion_data.get("shape_type", "")
	var shape_data = explosion_data.get("shape_data", {})
	
	match shape_type:
		"CircleShape2D":
			var radius = shape_data.get("radius", 50.0)
			return Rect2(center.x - radius, center.y - radius, radius * 2, radius * 2)
		"RectangleShape2D":
			var size = shape_data.get("size", Vector2(50, 50))
			return Rect2(center.x - size.x/2, center.y - size.y/2, size.x, size.y)
		_:
			return Rect2(center, Vector2.ZERO)

func is_point_in_shape(point: Vector2, center: Vector2, explosion_data: Dictionary) -> bool:
	"""Check if point is inside the destruction shape"""
	
	var shape_type = explosion_data.get("shape_type", "")
	var shape_data = explosion_data.get("shape_data", {})
	
	match shape_type:
		"CircleShape2D":
			var radius = shape_data.get("radius", 50.0)
			return point.distance_to(center) <= radius
		"RectangleShape2D":
			var size = shape_data.get("size", Vector2(50, 50))
			var rect = Rect2(center - size/2, size)
			return rect.has_point(point)
		_:
			return false
