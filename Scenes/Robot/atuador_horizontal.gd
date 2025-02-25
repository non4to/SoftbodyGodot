extends DampedSpringJoint2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var contraction_factor = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	%atuador_horizontal.rest_length = lerp(20, 100, contraction_factor) # Valores ajustáveis
	#print(%atuador_horizontal.rest_length)
