# Scripts/lobby.gd
extends Control

# UI References
@onready var create_btn: Button
@onready var join_btn: Button
@onready var ip_input: LineEdit
@onready var status_label: Label
@onready var players_list: ItemList
@onready var start_btn: Button

# Network state
var is_host: bool = false

func _ready():
	_create_ui()
	_setup_network_callbacks()

func _create_ui():
	# Background
	var bg = ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0.1, 0.1, 0.15, 1.0)
	add_child(bg)
	
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	# Centralização para tela 1152x648
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_vbox.size = Vector2(350, 400)
	main_vbox.position = Vector2(-175, -200)
	
	# Title
	var title = Label.new()
	title.text = "🎮 GOGUNNER LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	main_vbox.add_child(title)
	
	# Separator
	var sep1 = HSeparator.new()
	main_vbox.add_child(sep1)
	
	# Create Button
	var create_label = Label.new()
	create_label.text = "🏠 Criar Sala:"
	create_label.add_theme_font_size_override("font_size", 14)
	create_label.add_theme_color_override("font_color", Color.CYAN)
	main_vbox.add_child(create_label)
	
	create_btn = Button.new()
	create_btn.text = "🎮 CRIAR SALA"
	create_btn.custom_minimum_size = Vector2(320, 35)
	create_btn.add_theme_font_size_override("font_size", 14)
	create_btn.pressed.connect(_on_create_pressed)
	main_vbox.add_child(create_btn)
	
	# Separator
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)
	
	# Join Section
	var join_label = Label.new()
	join_label.text = "🔗 Entrar em Sala:"
	join_label.add_theme_font_size_override("font_size", 14)
	join_label.add_theme_color_override("font_color", Color.CYAN)
	main_vbox.add_child(join_label)
	
	ip_input = LineEdit.new()
	ip_input.text = "127.0.0.1"
	ip_input.placeholder_text = "Digite o IP do host"
	ip_input.custom_minimum_size = Vector2(320, 25)
	ip_input.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(ip_input)
	
	join_btn = Button.new()
	join_btn.text = "🔗 CONECTAR"
	join_btn.custom_minimum_size = Vector2(320, 35)
	join_btn.add_theme_font_size_override("font_size", 14)
	join_btn.pressed.connect(_on_join_pressed)
	main_vbox.add_child(join_btn)
	
	# Separator
	var sep3 = HSeparator.new()
	main_vbox.add_child(sep3)
	
	# Status
	status_label = Label.new()
	status_label.text = "🔌 Aguardando ação..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	main_vbox.add_child(status_label)
	
	# Players
	var players_label = Label.new()
	players_label.text = "👥 Players Conectados:"
	players_label.add_theme_font_size_override("font_size", 14)
	players_label.add_theme_color_override("font_color", Color.CYAN)
	main_vbox.add_child(players_label)
	
	players_list = ItemList.new()
	players_list.custom_minimum_size = Vector2(320, 60)
	players_list.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(players_list)
	
	# Start Button
	start_btn = Button.new()
	start_btn.text = "▶️ INICIAR JOGO"
	start_btn.custom_minimum_size = Vector2(320, 40)
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.modulate = Color.GREEN
	start_btn.pressed.connect(_on_start_pressed)
	start_btn.visible = false
	main_vbox.add_child(start_btn)

func _setup_network_callbacks():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# ===== BUTTON HANDLERS =====
func _on_create_pressed():
	print("🎮 [LOBBY] Criando sala...")
	
	if NetworkManager.create_server():
		is_host = true
		_update_ui_for_host()
		_add_player_to_list(1, "Player 1 (Host)")
	else:
		status_label.text = "❌ Erro ao criar sala!"

func _on_join_pressed():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "❌ Digite um IP válido!"
		return
	
	print("🔗 [LOBBY] Conectando em ", ip)
	
	if NetworkManager.join_server(ip):
		status_label.text = "🔗 Conectando..."
		_disable_connection_buttons()
	else:
		status_label.text = "❌ Erro ao conectar!"

func _on_start_pressed():
	if not is_host:
		return
	
	if players_list.item_count < 2:
		status_label.text = "❌ Precisa de pelo menos 2 players!"
		return
	
	print("▶️ [LOBBY] Iniciando jogo...")
	start_game.rpc()

# ===== NETWORK CALLBACKS =====
func _on_peer_connected(id: int):
	print("🟢 [LOBBY] Player conectou: ", id)
	
	if is_host:
		_add_player_to_list(id, "Player " + str(id))
		status_label.text = "✅ Player " + str(id) + " conectou!"
		
		if players_list.item_count >= 2:
			start_btn.visible = true

func _on_peer_disconnected(id: int):
	print("🔴 [LOBBY] Player desconectou: ", id)
	
	if is_host and players_list.item_count < 2:
		start_btn.visible = false

func _on_connected_to_server():
	print("✅ [LOBBY] Conectado ao servidor!")
	status_label.text = "✅ Conectado! Aguardando host iniciar..."

func _on_connection_failed():
	print("❌ [LOBBY] Falha na conexão!")
	status_label.text = "❌ Falha na conexão!"
	_enable_connection_buttons()

# ===== UI HELPERS =====
func _update_ui_for_host():
	status_label.text = "🎮 Sala criada! Aguardando players..."
	_disable_connection_buttons()

func _disable_connection_buttons():
	create_btn.disabled = true
	join_btn.disabled = true
	ip_input.editable = false

func _enable_connection_buttons():
	create_btn.disabled = false
	join_btn.disabled = false 
	ip_input.editable = true

func _add_player_to_list(id: int, name: String):
	players_list.add_item(name)

# ===== GAME START =====
@rpc("authority", "call_local", "reliable")
func start_game():
	print("🚀 [LOBBY] Iniciando jogo para todos!")
	get_tree().change_scene_to_file("res://Scenes/arena.tscn")
