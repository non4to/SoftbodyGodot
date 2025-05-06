extends Area2D

const ROBOT = preload("res://Scenes/Robot/robot.tscn")
var bodiesInside:int = 0
var AllowedToSpawn:bool = true
@export var delay:int = 1
@export var work:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	if Global.Step%delay==0:
		spawn_robot(position)
		
func spawn_robot(origin:Vector2):
	if work and AllowedToSpawn and Global.QtyRobotsCreatedBySpawner<Global.StartPopulation:
		Global.QtyRobotsCreatedBySpawner += 1
		var robot = ROBOT.instantiate()
		robot.position = origin
		robot.Energy = robot.MaxEnergyPossible
		Global.initialize_random_gene(robot)
		get_parent().add_child(robot)
		LogManager.log_bot(robot, str(self.name))
	if Global.QtyRobotsCreatedBySpawner >= Global.StartPopulation:
		self.queue_free()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	bodiesInside += 1
	AllowedToSpawn = false

func _on_area_2d_body_exited(_body: Node2D) -> void:
	bodiesInside -= 1
	if bodiesInside==0:
		AllowedToSpawn = true
