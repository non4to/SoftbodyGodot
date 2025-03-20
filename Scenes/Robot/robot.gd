extends Node2D

var Bones = []
const CenterBoneIndex = 4      #Which is the bone in the center of the robot -> Force is applied on it
const MaxForcePossible = 100   #Maximum Force possible
const MaxEnergyPossible = 300  #Maximum Energy possible
const MovingEnergyMult = 0.005 #Multiply this by the Force of the movement to obtain the Energy Cost
const ReproductionCost = 0.5   #Multiply this value by the max Energy value of created (not max Energy possible)

var RobotID: String 
var Gene: Array[int] = [0]
var Energy: float = 0
var Metabolism: float = MaxEnergyPossible*0.001

var direction_x = 1
var direction_y = 1
var power_x = 0
var power_y = 0
var current_collisions = 0

## Genes: velocity value, Energy
## 4 sensors: one of each side.

# Called when the node enters the scene tree for the first time.

func _init(Gene:Array[int] = [0]) -> void:
	#Gene
	#[MaxEnergy,Metabolism]
	self.Gene = Gene
	if self.Gene.size()==1:
		print(self.Gene)

func _ready() -> void:
	start_robot() #ID to the robot and its Bones
	#print(is_unit_vector())
	
func _process(delta: float) -> void:
	$"SoftBody2D/Bone-4/Label".text = str(Energy)
	pass
	#print(Bones[CenterBoneIndex].linear_velocity)	

func _physics_process(delta: float) -> void:	
	pass
	metabolize()
	var directions = [-1,0,1]
	if Energy > 0:
		if randf() < 0.1:
			if randf() < 0.5:
				direction_x = directions[randi()%directions.size()]
				direction_y = directions[randi()%directions.size()]
			move_to_direction(Vector2(direction_x,0),MaxForcePossible)
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
func metabolize() -> void:
	Energy -= Metabolism
	if Energy < 0: Energy = 0 
#---------------------------------------
func _on_sensor_body_entered(body: Node2D) -> void:
	if not(body.is_in_group(RobotID)): #check if the sensor is not colliding with its own body
		pass
		#print(body)
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
	if (collider.is_in_group("food")):
		Energy += collider.EnergyGiven
		collider.queue_free()
	#if (other_thing.is_in_group("bone"))and not(other_thing.is_in_group(RobotID)):
		#pass
		#print("collidi com outro robo!")
	#print("collidi com algo!", other_thing)
	#current_collisions += 1
	#direction *= -1
	#print(my_bone, other_thing)
#---------------------------------------
func movement_rules(collision_point:Node):
# A ideia é fazer regras baseado onde detectou colisão
# São quatro opções: 
	#Se mover na direção da colisão. 
	#Se mover na direção oposta a colisão.
	#Ficar Parado.
	#Se mover em uma direção aleatória.
# São as situações:
	
# Tipo: Se A colisão foi em X>minha posicao e Y< que minha posição, S	

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
