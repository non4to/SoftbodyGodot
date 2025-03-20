extends Camera2D

var moving = false
var lastPosition = Vector2()

func _input(event):
	# Quando o botão do meio for pressionado, começa a arrastar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		moving = event.pressed
		lastPosition = event.position  # Salva a posição inicial do clique

	# Se o mouse se mover enquanto estiver segurando o botão do meio
	elif event is InputEventMouseMotion and moving:
		var diferenca = lastPosition - event.position
		position += diferenca  # Move a câmera na direção oposta ao movimento do mouse
		lastPosition = event.position  # Atualiza a última posição do mouse

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom *= 1.1  # Aumenta o zoom (aproxima)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom /= 1.1  # Diminui o zoom (afasta)
