extends Node2D
 
const ROBOT = preload("res://Scenes/Robot/robot.tscn")
const TESTSPRING = preload("res://Scenes/TEST-SCENES/linked_bot.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_spawners()
	for spawner in Global.RobotSpawners:
		spawner.spawn_robot(spawner.position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$SubViewportContainer/SubViewport/Label.text = "Alive: "+str(Global.QtyRobotsAlive)
	$SubViewportContainer/SubViewport/Label2.text = str(Global.Step)
	# $SubViewportContainer/SubViewport/Label3.text = str(Global.BotsAtEnergyBank)
	# $SubViewportContainer/SubViewport/Label4.text = str(Global.FreeBanks)

	#$SubViewportContainer/SubViewport/Label2.text = "Robot1EnBank: "+str($SubViewportContainer/SubViewport/Robot.EnergyBankIndex)+ "; Robot1En: "+ str($SubViewportContainer/SubViewport/Robot.get_current_energy())
	#$SubViewportContainer/SubViewport/Label3.text = "Robot2EnBank: "+str($SubViewportContainer/SubViewport/Robot2.EnergyBankIndex)+ "; Robot2En: "+ str($SubViewportContainer/SubViewport/Robot2.get_current_energy())
	# print(Global.BotsAtEnergyBank)
	# print("Step: "+str(Step)+"; E.Bank: " + str(Global.EnergyBank))
	if (Global.StopStep>0)and(Global.Step > Global.StopStep):
		LogManager.save_log()
		get_tree().quit()

func _physics_process(_delta: float) -> void:
	pass

func _input(event):
	if event.is_action_released("toogle_spawn_robot"):
		make_robot(50,50)
	if event.is_action_released("left_mouse_click"):  # Ou use "ui_accept" se for a tecla padrão
		var mouse_position =  get_viewport().get_final_transform().basis_xform(get_global_mouse_position())
		# var mouse_position = get_global_mouse_position()  # Obtém a posição global do mouse
		make_robot(mouse_position.x, mouse_position.y)  # Spawna o robô nessa posição
	if event.is_action_released("esc"):
		LogManager.save_log()
		get_tree().quit()

func make_robot(x:int,y:int):
	var robot = ROBOT.instantiate()
	#var robot = TESTSPRING.instantiate()
	robot.position = Vector2(x,y)
	$SubViewportContainer/SubViewport.add_child(robot)

func get_spawners():
	for node in get_tree().get_nodes_in_group("robot-spawner"):#$"SubViewportContainer/SubViewport".get_children():
		if (node.is_in_group("robot-spawner")):
			Global.RobotSpawners.append(node)
