# NetworkManager.gd - WebSocket para melhor compatibilidade com ngrok
extends Node

const PORT = 8080
const MAX_PLAYERS = 2

var multiplayer_peer: WebSocketMultiplayerPeer

func _ready():
	print("🔧 [NETWORK] NetworkManager WebSocket iniciado")
	
	# Conectar callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_server():
	print("🎮 [NETWORK] Criando servidor WebSocket...")
	print("🔧 [NETWORK] Porta: ", PORT, " | Max players: ", MAX_PLAYERS)
	
	multiplayer_peer = WebSocketMultiplayerPeer.new()
	
	var error = multiplayer_peer.create_server(PORT, "*")
	
	if error != OK:
		print("❌ [NETWORK] Erro ao criar servidor WebSocket: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	print("✅ [NETWORK] Servidor WebSocket criado!")
	print("🌐 [NETWORK] Aceita conexões de qualquer IP na porta ", PORT)
	return true

func join_server(address: String):
	print("🔗 [NETWORK] Conectando WebSocket em: ws://", address, ":", PORT)
	
	address = address.strip_edges()
	if address.is_empty():
		print("❌ [NETWORK] Endereço vazio!")
		return false
	
	multiplayer_peer = WebSocketMultiplayerPeer.new()
	var websocket_url = "ws://" + address + ":" + str(PORT)
	
	var error = multiplayer_peer.create_client(websocket_url)
	
	if error != OK:
		print("❌ [NETWORK] Erro ao conectar WebSocket: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	print("🚀 [NETWORK] Cliente WebSocket criado!")
	return true

func join_ngrok_server(ngrok_url: String):
	print("🔗 [NETWORK] Conectando WebSocket via ngrok: ", ngrok_url)
	
	var parts = ngrok_url.split(":")
	if parts.size() != 2:
		print("❌ [NETWORK] Formato inválido! Use: host:porta")
		return false
	
	var host = parts[0]
	var port = int(parts[1])
	
	# Para ngrok, usamos o host e porta diretamente
	multiplayer_peer = WebSocketMultiplayerPeer.new()
	var websocket_url = "ws://" + host + ":" + str(port)
	
	print("🔧 [NETWORK] Conectando em: ", websocket_url)
	
	var error = multiplayer_peer.create_client(websocket_url)
	
	if error != OK:
		print("❌ [NETWORK] Erro WebSocket ngrok: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	print("🚀 [NETWORK] Cliente WebSocket ngrok criado!")
	return true

# ===== CALLBACKS =====
func _on_peer_connected(id: int):
	print("🟢 [NETWORK] Player conectou via WebSocket: ", id)

func _on_peer_disconnected(id: int):
	print("🔴 [NETWORK] Player desconectou: ", id)

func _on_connected_to_server():
	print("✅ [NETWORK] Conectado ao servidor WebSocket!")

func _on_connection_failed():
	print("❌ [NETWORK] Falha na conexão WebSocket!")

func _on_server_disconnected():
	print("🔴 [NETWORK] SERVIDOR WEBSOCKET DESCONECTOU!")
	get_tree().quit()
