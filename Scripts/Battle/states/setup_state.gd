class_name SetupState extends BattleState

func enter():
	log_state("Iniciando setup da batalha...")
	
	# Aguarda um frame para garantir que tudo está carregado
	await get_tree().process_frame
	
	_find_and_register_players()
	
	# VALIDAÇÃO CRÍTICA
	if not battle_manager.validate_battle_ready():
		log_state("❌ Setup falhou - players insuficientes")
		return
	
	log_state("Setup completo! Iniciando primeiro turno...")
	
	# Transita para o primeiro turno
	state_machine.start_turn()

func execute(delta: float):
	# SetupState não precisa de lógica contínua
	pass

func exit():
	log_state("Saindo do setup...")

# ===== MÉTODOS ESSENCIAIS =====

func _find_and_register_players():
	"""Encontra todos os players na cena atual"""
	log_state("Procurando players na cena...")
	
	var found_players: Array[Player] = []
	
	# Busca por nodes do tipo Player
	var scene_tree = get_tree()
	if scene_tree and scene_tree.current_scene:
		_recursive_find_players(scene_tree.current_scene, found_players)
	
	# Registra players encontrados
	if found_players.size() >= 1:
		battle_manager.players = found_players
		log_state("Encontrados " + str(found_players.size()) + " players")
		
		# Se só tem 1 player, cria um dummy para teste
		if found_players.size() == 1:
			_create_dummy_player_for_testing()
	else:
		log_state("❌ ERRO: Nenhum player encontrado!")

func _recursive_find_players(node: Node, players: Array[Player]):
	"""Busca recursiva por players na árvore"""
	if node is Player:
		players.append(node)
		log_state("Player encontrado: " + node.name)
	
	for child in node.get_children():
		_recursive_find_players(child, players)

func _create_dummy_player_for_testing():
	"""Cria um segundo player dummy para testar o sistema de turnos"""
	log_state("Criando player dummy para teste...")
	
	var original_player = battle_manager.players[0]
	var dummy_player = original_player.duplicate()
	
	# Posiciona o dummy em local diferente
	dummy_player.global_position = original_player.global_position + Vector2(200, 0)
	dummy_player.name = "Player2_Dummy"
	
	# Adiciona à cena
	get_tree().current_scene.add_child(dummy_player)
	
	# Registra no battle manager
	battle_manager.players.append(dummy_player)
	
	log_state("Player dummy criado: " + dummy_player.name)
