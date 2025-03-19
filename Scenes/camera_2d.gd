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
