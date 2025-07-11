# NetworkManager.gd - VERSÃO SUPER SIMPLES
extends Node

const PORT = 8080
const MAX_PLAYERS = 2

var multiplayer_peer: ENetMultiplayerPeer

func _ready():
	print("🔧 [NETWORK] NetworkManager iniciado")
	
	# Conectar callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_scene_changed():
	print("🎬 [GLOBAL] CENA MUDOU! Current scene: ", get_tree().current_scene.scene_file_path if get_tree().current_scene else "NONE")

func create_server():
	print("🎮 [NETWORK] Criando servidor...")
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		print("❌ [NETWORK] Erro ao criar servidor: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	print("✅ [NETWORK] Servidor criado - ID: ", multiplayer.get_unique_id())
	return true

func join_server(address: String):
	print("🔗 [NETWORK] Conectando em ", address, ":", PORT)
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(address, PORT)
	
	if error != OK:
		print("❌ [NETWORK] Erro ao conectar: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	return true

# ===== CALLBACKS =====
func _on_peer_connected(id: int):
	print("🟢 [NETWORK] Player conectou: ", id)

func _on_peer_disconnected(id: int):
	print("🔴 [NETWORK] Player desconectou: ", id)

func _on_connected_to_server():
	print("✅ [NETWORK] Conectado ao servidor!")

func _on_connection_failed():
	print("❌ [NETWORK] Falha na conexão!")

func _on_server_disconnected():
	print("🔴 [NETWORK] SERVIDOR DESCONECTOU!")
	
	# Forçar saída IMEDIATA do processo
	# Ao invés de tentar "salvar" a sessão
	print("🔴 [NETWORK] Forçando saída do cliente...")
	get_tree().quit()
