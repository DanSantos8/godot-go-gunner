# Scripts/auto_connect.gd
extends Node

func _ready():
	print("🤖 [AUTO] Iniciando auto-connect...")
	_setup_disconnect_detection()
	
	# Aguarda 1 segundo para tudo carregar
	await get_tree().create_timer(1.0).timeout
	_auto_setup()

func _setup_disconnect_detection():
	# Detecta quando servidor se desconecta
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Detecta quando aplicação vai fechar
	get_tree().set_auto_accept_quit(false)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_app_closing()

func _auto_setup():
	if OS.has_feature("editor"):
		# SE FOR EDITOR = SERVIDOR
		print("📝 [AUTO] Editor detectado - Criando SERVIDOR")
		NetworkManager.create_server()
	else:
		# SE FOR EXECUTÁVEL = CLIENTE  
		print("💻 [AUTO] Executável detectado - Conectando como CLIENTE")
		NetworkManager.join_server("127.0.0.1")

func _on_server_disconnected():
	print("🔴 [AUTO] Servidor desconectou! Fechando cliente...")
	get_tree().quit()

func _handle_app_closing():
	print("🔴 [AUTO] Aplicação fechando...")
	
	if multiplayer.is_server():
		print("🔴 [AUTO] Servidor fechando - desconectando todos clientes")
		# Servidor avisa clientes antes de fechar
		_notify_server_shutdown.rpc()
		
		# Aguarda um pouco para RPC chegar
		await get_tree().create_timer(0.1).timeout
	
	get_tree().quit()

@rpc("authority", "call_local", "reliable")
func _notify_server_shutdown():
	if not multiplayer.is_server():
		print("🔴 [AUTO] Servidor mandou fechar - encerrando cliente")
		get_tree().quit()
