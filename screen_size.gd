extends Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = get_tree().root.size  # Retorna um Vector2 com largura e altura
	var x = screen_size.x
	var y = screen_size.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
