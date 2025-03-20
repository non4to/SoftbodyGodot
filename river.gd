extends Area2D

var CurrentForce = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: RigidBody2D) -> void:
	body.apply_central_force(Vector2(0,-1)*CurrentForce)
