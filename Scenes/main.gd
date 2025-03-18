extends Node2D
 
const ROBOTS_NUMBER = 0
const ROBOT = preload("res://Scenes/Robot/robot.tscn")
const ROBOT2 = preload("res://Scenes/myRobot/myrobot2.tscn")
var robots = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawn_robot = false
	var screen_width = 1000
	var screen_height = 500
	for i in range(ROBOTS_NUMBER):
		make_robot(randf_range(0,screen_width),randf_range(0,screen_height))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass	
	
func _input(event):
	if event.is_action_released("toogle_spawn_robot"):
		make_robot(50,50)
	if event.is_action_released("left_mouse_click"):  # Ou use "ui_accept" se for a tecla padrão
		var mouse_position = get_global_mouse_position()  # Obtém a posição global do mouse
		make_robot(mouse_position.x, mouse_position.y)  # Spawna o robô nessa posição

func make_robot(x:int,y:int):
	var robot = ROBOT.instantiate()
	robot.position = Vector2(x,y)
	add_child(robot)
	robots.append(robot)	
