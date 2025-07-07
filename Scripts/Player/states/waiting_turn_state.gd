class_name WaitingTurnState extends State

func enter():
	log_state("Player aguardando turno...")
	
	# Player fica em idle visual
	player.get_node("PlayerAnimation").play("Idle")
	player.velocity = Vector2.ZERO
	
	# Conecta eventos de colisão para receber dano
	if not MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.connect(_on_projectile_collision)

func execute(delta: float):
	# Player não pode fazer nada durante WaitingTurn
	# Apenas aguarda ser atingido ou turno acabar
	pass

func exit():
	log_state("Saindo do WaitingTurn...")
	
	# Desconecta eventos
	if MessageBus.projectile_collision.is_connected(_on_projectile_collision):
		MessageBus.projectile_collision.disconnect(_on_projectile_collision)

# ===== EVENT HANDLERS =====

func _on_projectile_collision(collision_type: String, position: Vector2, target: Node):
	# Só reage se o target for este player
	if collision_type == "player" and target == player:
		log_state("💥 Player atingido por projétil!")
		_handle_hit(position)

func _handle_hit(hit_position: Vector2):
	"""Processa quando o player é atingido"""
	
	# TODO: Aplicar dano, diminuir vida, etc.
	# Por enquanto, só animação e feedback visual
	
	_play_hit_animation()
	_show_damage_effect(hit_position)
	
	log_state("Player sofreu dano na posição: " + str(hit_position))

func _play_hit_animation():
	"""Animação de receber dano"""
	
	# Pisca vermelho (efeito visual simples)
	var sprite = player.get_node("PlayerAnimation")
	var tween = create_tween()
	
	# Pisca vermelho 3 vezes
	for i in range(3):
		tween.tween_method(_set_sprite_modulate, Color.WHITE, Color.RED, 0.1)
		tween.tween_method(_set_sprite_modulate, Color.RED, Color.WHITE, 0.1)
	
	log_state("Executando animação de dano...")

func _set_sprite_modulate(color: Color):
	"""Helper para o tween"""
	var sprite = player.get_node("PlayerAnimation")
	sprite.modulate = color

func _show_damage_effect(hit_position: Vector2):
	"""Mostra efeito visual no ponto de impacto"""
	
	# TODO: Criar partículas, numbers pop-up, etc.
	# Por enquanto, só log
	
	log_state("Efeito de dano na posição: " + str(hit_position))

func log_state(message: String):
	print("🎮 [WAITING_TURN] ", player.name, " | ", message)
