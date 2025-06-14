extends StaticBody2D

@onready var terrain_path = $TerrainPath
@onready var terrain_visual = $TerrainVisual
@onready var terrain_collision = $TerrainCollision

func print_debug_info():
	print("Pontos do terreno visual: ", terrain_visual.polygon.size())
	print("Pontos da colisão: ", terrain_collision.polygon.size())

	# ADICIONE ESSAS LINHAS:
	print("Collision disabled? ", terrain_collision.disabled)
	print("Primeiro ponto colisão: ", terrain_collision.polygon[0])
	print("Último ponto colisão: ", terrain_collision.polygon[-1])


func _ready():
	create_curved_terrain()
	setup_terrain_texture()
	print_debug_info() # Adicione esta linha

func create_curved_terrain():
	var curve = terrain_path.curve

	# Converter para polígono
	var baked_points = curve.get_baked_points()
	var terrain_points = create_closed_polygon(baked_points)

	# Aplicar aos nós visuais e de colisão
	terrain_visual.polygon = terrain_points
	terrain_collision.polygon = terrain_points
	
	terrain_collision.set_polygon(terrain_points)
	call_deferred("_on_collision_ready")
	
	terrain_visual.color = Color.WHITE
	
	print(terrain_collision.polygon)
	
func create_closed_polygon(curve_points: PackedVector2Array) -> PackedVector2Array:
	var points = PackedVector2Array()

	points.append_array(curve_points)

	var last_point = curve_points[-1]
	var first_point = curve_points[0]

	points.append(Vector2(last_point.x, 500))  
	points.append(Vector2(first_point.x, 500)) 

	return points

func setup_terrain_texture():
	var texture = preload("res://Sprites/Tiles/metal-03.png")
	
	terrain_visual.texture = texture
	terrain_visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	terrain_visual.texture_scale = Vector2(2, 2)
	terrain_visual.antialiased = true
