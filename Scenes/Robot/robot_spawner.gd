extends Area2D

const ROBOT = preload("res://Scenes/Robot/robot.tscn")
var bodiesInside:int = 0
var AllowedToSpawn:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
		
func spawn_robot(origin:Vector2):
	if AllowedToSpawn:
		var robot = ROBOT.instantiate()
		robot.position = origin
		get_parent().add_child(robot)

func _on_body_entered(body: Node2D) -> void:
	bodiesInside += 1
	AllowedToSpawn = false

func _on_body_exited(body: Node2D) -> void:
	bodiesInside -= 1
	if bodiesInside==0:
		AllowedToSpawn = true
