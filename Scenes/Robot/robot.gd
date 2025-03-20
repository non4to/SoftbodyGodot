extends Node2D

var Bones = []
const CenterBoneIndex: int = 4      #Which is the bone in the center of the robot -> Force is applied on it
@export var MaxForcePossible: int = 1   #Maximum Force possible
const MaxEnergyPossible: int = 300  #Maximum Energy possible
const MovingEnergyMult: float = 0.005 #Multiply this by the Force of the movement to obtain the Energy Cost
const ReproductionCost: float = 0.5   #Multiply this value by the max Energy value of created (not max Energy possible)

var RobotID: String 								#Robot unique identifier
var Gene: Array[int] = [0]							#Gene Array
var Energy: float = 0								#Current Energy
var Metabolism: float = MaxEnergyPossible*0.001		#Metabolism. Every step this value is deduced from Energy
var MovementDirection: Vector2 						#MovementDirection
var ChangeDirectionDelay: int = 15					#Delay to allow change in Movement Direction
var StepsToChangeDirection: int = 0					#Counter to allow change in Movement Direction
var AllowDirectionChange: bool = true				#Self explanatory
var MovementRules: Array[Vector2] = []				#Has the movement direction that will be taken after a collision happens in the corresponding bone

var direction_x = 1
var direction_y = 1
var power_x = 0
var power_y = 0
var current_collisions = 0


## Genes: velocity value, Energy
## 4 sensors: one of each side.

# Called when the node enters the scene tree for the first time.

func _init(Gene=9) -> void:
	pass
	#Gene
	#[MaxEnergy,Metabolism]
	#self.Gene = Gene
	#if self.Gene==9:
		#self.Gene = 0b01011010101010101101110001110101010101111010
#---------------------------------------
func _ready() -> void:
	start_robot() #ID to the robot and its Bones
	MovementDirection = Vector2(cos(deg_to_rad(randi_range(0,360))),sin(deg_to_rad(randi_range(0,360))))
	
	#gene_translation()
#---------------------------------------
func _process(delta: float) -> void:
	$"SoftBody2D/Bone-4/Label".text = str(Energy)
	$"SoftBody2D/Bone-4/Label2".text = str(StepsToChangeDirection)
	pass
#---------------------------------------
func _physics_process(delta: float) -> void:	
	pass
	var directions = [-1,0,1]
	metabolize()
	if not AllowDirectionChange:
		StepsToChangeDirection += 1
		if StepsToChangeDirection > ChangeDirectionDelay:
			AllowDirectionChange = true
	
	#if StepsToChangeDirection > 5*ChangeDirectionDelay:
		#if randf() < 0.99:
			#if randf() < 0.5:
				#direction_x = directions[randi()%directions.size()]
				#direction_y = directions[randi()%directions.size()]
				#change_direction(Vector2(direction_x,direction_y))
		
	if Energy > 0:	
		move_to_direction(MovementDirection,MaxForcePossible)
			#Bones[CenterBoneIndex].apply_central_force(Vector2(direction_x*power_x, direction_y*power_y))
#---------------------------------------
func start_robot() -> void:
	#Start variables
	Energy = MaxEnergyPossible
	#Builds an ID to robot and adds robot and its Bones to this group
	RobotID = "id_" + str(get_instance_id())
	add_to_group("robot")
	add_to_group(RobotID)
	for bone in get_node("SoftBody2D").get_children():
		if bone.is_class("RigidBody2D") and ("Bone" in bone.name):
			Bones.append(bone)	
			bone.add_to_group("bone")
			bone.add_to_group(RobotID)
			#bone.set_script(bone_script)
			#bone.connect("bone_collided_with_robot", _on_bone_collided_with_robot)
			bone.connect("bone_collided", _on_bone_collided)
			bone.connect("bone_collision_finished", _on_bone_collision_finished)
#---------------------------------------
func gene_translation() -> void:
	# Each bone has 5 bits: [0~4]=Towards/[5~9]=Avoid/[10~14]=+90deg/[15~19]=-90deg/[20~25]=Stop/[26~31]=Random
	var bonesLimits = [[0,4],[5,9],[10,14],[15,19],[20,24],[25,29],[30,34],[35,39],[40,44]]
	# ChangeDirectionDelay has 7 bits -> Delay = Direct binary conversion
	var towardsValues = [get_direction_vector(Bones[4],Bones[0]), 
						get_direction_vector(Bones[4],Bones[1]),
						get_direction_vector(Bones[4],Bones[2]),
						get_direction_vector(Bones[4],Bones[3]),
						get_direction_vector(Bones[4],Bones[4]),
						get_direction_vector(Bones[4],Bones[5]),
						get_direction_vector(Bones[4],Bones[6]),
						get_direction_vector(Bones[4],Bones[7]),
						get_direction_vector(Bones[4],Bones[8])]
	for i in range(Bones.size()):
		print(Gene[bonesLimits[i][0]])
		

#---------------------------------------
func metabolize() -> void:
	Energy -= Metabolism
	if Energy < 0: Energy = 0 
#---------------------------------------
func change_direction(direction:Vector2) -> void:
	if AllowDirectionChange:
		#print(MovementDirection)
		MovementDirection = direction
		StepsToChangeDirection = 0
		AllowDirectionChange = false
#---------------------------------------
#func _on_sensor_body_entered(body: Node2D) -> void:
	#if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		#pass
		#print(position)
		#print(body, body.position)
		#print()
#---------------------------------------
func move_to_direction(direction:Vector2, withForce:float) -> void:
		if not is_unit_vector(direction):
			direction = direction.normalized()
		Bones[CenterBoneIndex].apply_central_impulse(direction*withForce)
		Energy -= withForce*MovingEnergyMult
#---------------------------------------
func is_unit_vector(vector:Vector2):
	return abs(vector.length_squared() - 1) < 0.001
#---------------------------------------
func _on_bone_collided(myBone:RigidBody2D,collider:Node):
	var collisionDirections = [get_direction_vector(Bones[4],Bones[0]), 
								get_direction_vector(Bones[4],Bones[1]),
								get_direction_vector(Bones[4],Bones[2]),
								get_direction_vector(Bones[4],Bones[3]),
								get_direction_vector(Bones[4],Bones[4]),
								get_direction_vector(Bones[4],Bones[5]),
								get_direction_vector(Bones[4],Bones[6]),
								get_direction_vector(Bones[4],Bones[7]),
								get_direction_vector(Bones[4],Bones[8])]
								
	if (collider.is_in_group("food")):
		Energy += collider.EnergyGiven
		collider.queue_free()
	
	var directions = [-1,0,1]
	for i in range(Bones.size()):
		if myBone==Bones[i] and AllowDirectionChange:
			print(myBone)
			change_direction(directions[randi()%directions.size()]*collisionDirections[i])

			
		
	#if (other_thing.is_in_group("bone"))and not(other_thing.is_in_group(RobotID)):
		#pass
		#print("collidi com outro robo!")
	#print("collidi com algo!", other_thing)
	#current_collisions += 1
	#direction *= -1
	#print(my_bone, other_thing)
#---------------------------------------
#func _on_redsensor_body_entered(body: Node2D) -> void:
	#if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		#if AllowDirectionChange:
			#print("red!")
			#change_direction(Vector2(1,0))
#
#func _on_greensensor_body_entered(body: Node2D) -> void:
	#if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		#if AllowDirectionChange:
			#print("green!")
			#change_direction(Vector2(0,1))
				#
#func _on_yellowsensor_body_entered(body: Node2D) -> void:
	#if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		#if AllowDirectionChange:	
			#print("yellow!")
			#change_direction(Vector2(-1,0))
		#
#func _on_bluesensor_body_entered(body: Node2D) -> void:
	#if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		#if AllowDirectionChange:	
			#print("blue!")
			#change_direction(Vector2(0,-1))
		
#---------------------------------------

func movement_rules(collision_point:Node):
	pass

#---------------------------------------
func contract(bone:RigidBody2D, in_bone_direction:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,in_bone_direction)
	bone.apply_central_force(direction*withForce)

func attach_bodies(my_bone:RigidBody2D, other_bone: RigidBody2D, side:String) -> void:
	print(my_bone,other_bone)
	var point1 = self.position
	var point2 = self.position
	var joint1 = PinJoint2D.new()
	var joint2 = PinJoint2D.new()

	
	if side == "left":
		point1 = Vector2(0,12.5) 
		point2 = Vector2(0,37.5)
	elif side == "right":
		point1 = Vector2(50,25)
		point2 = Vector2(50,50)
	elif side == "top":
		point1 = Vector2(12.5,0)
		point2 = Vector2(37.5,0)
	elif side == "bot":
		point1 = Vector2(25,50)
		point2 = Vector2(50,50)
		
	joint1.position = point1
	joint2.position = point2
	
	joint1.node_a = my_bone.get_path()
	joint1.node_b = other_bone.get_path()
	joint2.node_a = my_bone.get_path()
	joint2.node_b = other_bone.get_path()
	
	joint1.scale = Vector2(1.2,1.2)
	joint2.scale = Vector2(1.2,1.2)
	
	joint1.softness = 0.001
	joint2.softness = 0.001
	
	my_bone.add_child(joint1)
	my_bone.add_child(joint2)
	
func get_direction_vector(fromA:RigidBody2D,toB:RigidBody2D) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector

func _on_timer_timeout() -> void:
	pass
	#contract_blue(mult*maxForce)
	#contract_top(mult*maxForce)
	
		#$SoftBody2D.apply_impulse(Vector2(direction_x*power_x, direction_y*power_y))
#func _on_bone_collided_with_robot(my_bone:RigidBody2D,other_bone:RigidBody2D):
	#print(my_bone, other_bone)
	


func _on_bone_collision_finished(my_bone:RigidBody2D,other_thing:Node):
	#print(other_thing)
	current_collisions -= 1

#func setting_sensors() -> void:
	#var sensorsNames = ["red","green","yellow","blue"]
	#var sensorsSizes = [Vector2(12,25),Vector2(25,12),Vector2(12,25),Vector2(25,12)]
	#var sensorsPositions = [Vector2(-18,0),Vector2(0,-18),Vector2(18,0),Vector2(0,18)]   #point(0,0) is the position of CenterBoneIndex. The position of the rectangle is the center of it. For red: x=12(half of robot size - rounded down) + 6(half of sensor side size - round down). y=same as CenterBoneIndex y.
	#
	#for i in range(sensorsNames.size()):
		#var sensor = Area2D.new()
		#var collisionShape = CollisionShape2D.new()
		#var shape = RectangleShape2D.new()	
		#sensor.name = sensorsNames[i]
		#shape.size = sensorsSizes[i]
		#collisionShape.shape = shape
		#collisionShape.position = sensorsPositions[i]
		#sensor.add_child(collisionShape)
		#Bones[CenterBoneIndex].add_child(sensor)
