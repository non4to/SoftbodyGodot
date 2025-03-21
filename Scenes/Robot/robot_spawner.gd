extends Area2D

const ROBOT = preload("res://Scenes/Robot/robot.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
func spawn_robot(position:Vector2):
	var robot = ROBOT.instantiate()
	robot.position = Vector2(position)
	get_parent().add_child(robot)
	Global.Robots.append(robot)	
