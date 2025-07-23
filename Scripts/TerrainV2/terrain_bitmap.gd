class_name TerrainBitmapV2 extends StaticBody2D

# Node references
@onready var terrain_sprite: Sprite2D = $TerrainSprite
@onready var terrain_collision: CollisionPolygon2D = $TerrainCollision

# Core data
var terrain_image: Image
var terrain_bitmap: BitMap
var terrain_texture: ImageTexture

# Components
var crater_queue: CraterQueueV2
var shape_processor: ShapeProcessor

func _ready():
	# Connect to terrain collision events
	MessageBus.projectile_collided_with_terrain.connect(_on_terrain_collision)
	
	# Initialize components
	crater_queue = CraterQueueV2.new()
	shape_processor = ShapeProcessor.new()
	
	# Setup terrain from sprite texture
	_setup_terrain_from_texture()
	
	print("🏔️ [TERRAIN_V2] Initialized")

func _setup_terrain_from_texture():
	"""Convert PNG sprite to editable bitmap + collision"""
	
	var source_texture = terrain_sprite.texture
	if not source_texture:
		print("❌ [TERRAIN_V2] No texture found on TerrainSprite")
		return
	
	# Create editable image copy
	terrain_image = source_texture.get_image().duplicate()
	terrain_texture = ImageTexture.new()
	terrain_texture.set_image(terrain_image)
	terrain_sprite.texture = terrain_texture
	
	# Create bitmap for collision
	terrain_bitmap = BitMap.new()
	terrain_bitmap.create_from_image_alpha(terrain_image, 0.1)
	
	# Generate initial collision
	_update_collision()
	
	print("✅ [TERRAIN_V2] Terrain setup complete (", terrain_image.get_size(), ")")

func _update_collision():
	"""Generate CollisionPolygon2D from current bitmap"""
	
	var rect = Rect2(Vector2.ZERO, terrain_bitmap.get_size())
	var polygons = terrain_bitmap.opaque_to_polygons(rect, 2.0)
	
	if polygons.is_empty():
		print("⚠️ [TERRAIN_V2] No collision polygons generated")
		return
	
	# Center coordinates relative to sprite
	var sprite_size = terrain_sprite.texture.get_size()
	var offset = sprite_size / 2.0
	
	var centered_polygon = PackedVector2Array()
	for point in polygons[0]:
		centered_polygon.append(point - offset)
			
	call_deferred("_apply_collision_polygon", centered_polygon)
	print("🔧 [TERRAIN_V2] Collision updated (", centered_polygon.size(), " points)")

func _apply_collision_polygon(polygon: PackedVector2Array):
	terrain_collision.polygon = polygon
	print("🔧 [TERRAIN_V2] Collision updated (", polygon.size(), " points)")
	
func _update_visual():
	"""Update sprite texture from current image"""
	
	terrain_texture.update(terrain_image)
	print("🎨 [TERRAIN_V2] Visual updated")

func _on_terrain_collision(position: Vector2, explosion_data: Dictionary = {}):
	"""Handle terrain collision from MessageBus"""
	
	print("💥 [TERRAIN_V2] Terrain collision at: ", position)
	print("📊 [TERRAIN_V2] Explosion data: ", explosion_data)
	
	# Add to crater queue
	crater_queue.add_crater_request(position, explosion_data, _apply_crater_immediately)

func _apply_crater_immediately(position: Vector2, explosion_data: Dictionary):
	"""Apply crater destruction immediately (called by queue)"""
	
	print("🕳️ [TERRAIN_V2] Applying crater at: ", position)
	
	# Convert world position to local bitmap position
	var local_position = to_local(position)
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_position = local_position + sprite_size / 2.0
	
	# Process shape destruction
	var pixels_removed = shape_processor.apply_shape_destruction(
		terrain_image, 
		terrain_bitmap, 
		bitmap_position, 
		explosion_data
	)
	
	# Update visual and collision
	_update_visual()
	_update_collision()
	
	print("✅ [TERRAIN_V2] Crater applied - ", pixels_removed, " pixels removed")

# ===== PUBLIC API =====

func get_terrain_size() -> Vector2:
	return terrain_image.get_size() if terrain_image else Vector2.ZERO

func is_point_solid(world_position: Vector2) -> bool:
	"""Check if world position has solid terrain"""
	
	var local_pos = to_local(world_position)
	var sprite_size = terrain_sprite.texture.get_size()
	var bitmap_pos = local_pos + sprite_size / 2.0
	
	var x = int(bitmap_pos.x)
	var y = int(bitmap_pos.y)
	
	if x < 0 or x >= terrain_bitmap.get_size().x or y < 0 or y >= terrain_bitmap.get_size().y:
		return false
	
	return terrain_bitmap.get_bit(x, y)
