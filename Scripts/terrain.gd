extends StaticBody2D

@onready var terrain_path = $TerrainPath
@onready var terrain_visual = $TerrainVisual
@onready var terrain_collision = $TerrainCollision

# TODO refactor
@export var destruction_data: DestructionData

func print_debug_info():
	pass
	# print("Pontos do terreno visual: ", terrain_visual.polygon.size())
	# print("Pontos da colisão: ", terrain_collision.polygon.size())

	# ADICIONE ESSAS LINHAS:
	# print("Collision disabled? ", terrain_collision.disabled)
	# print("Primeiro ponto colisão: ", terrain_collision.polygon[0])
	# print("Último ponto colisão: ", terrain_collision.polygon[-1])


func _ready():
	add_to_group("terrain_manager")
	create_curved_terrain()
	setup_terrain_texture()
	MessageBus.projectile_collided_with_terrain.connect(_destroy_circular)
	
	if not destruction_data:
		destruction_data = DestructionData.new()
		destruction_data.type = DestructionData.DestructionType.CIRCULAR
		destruction_data.radius = 15.0

func create_curved_terrain():
	var curve = terrain_path.curve

	# Converter para polígono
	var baked_points = curve.get_baked_points()
	var terrain_points = create_closed_polygon(baked_points)

	# Aplicar aos nós visuais e de colisão
	terrain_visual.polygon = terrain_points
	terrain_collision.polygon = terrain_points
	
	terrain_collision.set_polygon(terrain_points)
	
	terrain_visual.color = Color.WHITE
		
func create_closed_polygon(curve_points: PackedVector2Array) -> PackedVector2Array:
	var points = PackedVector2Array()

	points.append_array(curve_points)

	var last_point = curve_points[-1]
	var first_point = curve_points[0]

	points.append(Vector2(last_point.x, 12))  
	points.append(Vector2(first_point.x, 12)) 

	return points

func setup_terrain_texture():
	var texture = preload("res://Sprites/Tiles/metal-03.png")
	
	terrain_visual.texture = texture
	terrain_visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	terrain_visual.texture_scale = Vector2(2, 2)
	terrain_visual.antialiased = true
	
func _destroy_circular(pos: Vector2):	
	# Converte posição global para local
	var local_pos = to_local(pos)
	
	# Cria círculo simples
	var circle = []
	for i in range(16):
		var angle = i * 2.0 * PI / 16
		var point = local_pos + Vector2(cos(angle), sin(angle)) * destruction_data.radius
		circle.append(point)
	
	# Pega o terreno atual
	var current_polygon = terrain_visual.polygon
	
	# Faz o "buraco"
	var result = Geometry2D.clip_polygons(current_polygon, circle)
	
	# Atualiza com TODOS os fragmentos
	if result.size() > 0:
		_update_terrain_with_fragments(result, terrain_visual, terrain_collision)
		MessageBus.projectile_destroyed.emit()

func _update_terrain_with_fragments(fragments: Array, visual_node: Polygon2D, collision_node: CollisionPolygon2D):
	# Encontra o maior fragmento (ilha principal)
	var main_fragment = _get_largest_fragment(fragments)
	
	# Atualiza o terreno principal
	visual_node.polygon = main_fragment
	collision_node.call_deferred("set_polygon", main_fragment)
	
	# Cria ilhas flutuantes para os outros fragmentos
	for i in range(fragments.size()):
		if fragments[i] != main_fragment and fragments[i].size() > 3: # Mínimo de 3 pontos
			call_deferred("_create_floating_island", fragments[i])

func _get_largest_fragment(fragments: Array) -> PackedVector2Array:
	var largest = fragments[0]
	var largest_area = _calculate_area(largest)
	
	for fragment in fragments:
		var area = _calculate_area(fragment)
		if area > largest_area:
			largest = fragment
			largest_area = area
	
	return largest

func _calculate_area(polygon: PackedVector2Array) -> float:
	var area = 0.0
	for i in range(polygon.size()):
		var j = (i + 1) % polygon.size()
		area += polygon[i].x * polygon[j].y - polygon[j].x * polygon[i].y
	return abs(area) * 0.5

func _create_floating_island(fragment: PackedVector2Array):
	# Cria nova ilha flutuante
	var island = StaticBody2D.new()

	# Visual da ilha
	var visual = Polygon2D.new()
	visual.polygon = fragment
	visual.texture = terrain_visual.texture # Copia textura original
	visual.texture_scale = terrain_visual.texture_scale

	# Colisão da ilha
	var collision = CollisionPolygon2D.new()
	collision.polygon = fragment

	# Monta a estrutura
	island.add_child(visual)
	island.add_child(collision)

	# Adiciona ao mesmo container
	add_child(island)
	
	island.global_position = global_position
