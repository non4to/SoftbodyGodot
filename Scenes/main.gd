extends Node2D
 
const ROBOT = preload("res://Scenes/Robot/robot.tscn")
const TESTSPRING = preload("res://Scenes/TEST-SCENES/linked_bot.tscn")

var RobotSpawners = []

var Step:int = 0
var FinalStep:int = 9999

var OldestAge:int = 0

@export var FPS:int = 1
@export var SaveFrames:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_spawners()
	for spawner in RobotSpawners:
		spawner.spawn_robot(spawner.position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$SubViewportContainer/SubViewport/Label.text = "Robots Number: "+str(Global.Robots.size())+"; Oldest age: "+str(OldestAge)
	$SubViewportContainer/SubViewport/Label2.text = str(Global.EnergyBank)
	$SubViewportContainer/SubViewport/Label3.text = str(Global.BotsAtEnergyBank)
	$SubViewportContainer/SubViewport/Label4.text = str(Global.FreeBanks)

	#$SubViewportContainer/SubViewport/Label2.text = "Robot1EnBank: "+str($SubViewportContainer/SubViewport/Robot.EnergyBankIndex)+ "; Robot1En: "+ str($SubViewportContainer/SubViewport/Robot.get_current_energy())
	#$SubViewportContainer/SubViewport/Label3.text = "Robot2EnBank: "+str($SubViewportContainer/SubViewport/Robot2.EnergyBankIndex)+ "; Robot2En: "+ str($SubViewportContainer/SubViewport/Robot2.get_current_energy())
	# print(Global.BotsAtEnergyBank)
	# print("Step: "+str(Step)+"; E.Bank: " + str(Global.EnergyBank))
	
	#if Global.Robots.size() < RobotSpawners.size():
		#for i in range(RobotSpawners.size()):
			#var rand_index:int = randi() % RobotSpawners.size()
			#while rand_index in used:
				#rand_index = randi() % RobotSpawners.size()			
			#used.append(rand_index)
			#RobotSpawners[rand_index].spawn_robot(RobotSpawners[rand_index].position)
	

			


func _physics_process(_delta: float) -> void:
	if Step > FinalStep:
		get_tree().quit()

	for i in range(Global.Robots.size()):
		if Global.Robots[i].Age > OldestAge:
			OldestAge = Global.Robots[i].Age


	#SaveFrame
	if (SaveFrames) and (Step%FPS==0):
		save_frame()
	Step += 1

func _input(event):
	if event.is_action_released("toogle_spawn_robot"):
		make_robot(50,50)
	if event.is_action_released("left_mouse_click"):  # Ou use "ui_accept" se for a tecla padrão
		var mouse_position =  get_viewport().get_final_transform().basis_xform(get_global_mouse_position())
		
		# var mouse_position = get_global_mouse_position()  # Obtém a posição global do mouse
		make_robot(mouse_position.x, mouse_position.y)  # Spawna o robô nessa posição

func make_robot(x:int,y:int):
	var robot = ROBOT.instantiate()
	#var robot = TESTSPRING.instantiate()
	robot.position = Vector2(x,y)
	robot.name = robot.RobotID
	$SubViewportContainer/SubViewport.add_child(robot)
	Global.Robots.append(robot)	

func get_spawners():
	for node in $"SubViewportContainer/SubViewport".get_children():
		if (node.is_in_group("robot-spawner")):
			RobotSpawners.append(node)
	
func save_frame() -> void:
	await RenderingServer.frame_post_draw  
	var img = get_viewport().get_texture().get_image()
	img.save_png("res://frames/frame_%08d.png" % Step)
