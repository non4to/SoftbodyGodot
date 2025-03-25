extends Node2D

#
@export var JointDamping:float = 150
@export var JointStiffness:float = 1
@export var JointLength:float = 300
@export var JointRestLen:float = 20



#body
var Bones = []
var RobotID: String 								#Robot unique identifier
const CenterBoneIndex: int = 4      #Which is the bone in the center of the robot -> Force is applied on it

#energy economy
var Energy: float = 0								#Current Energy
const MaxEnergyPossible: int = 300  #Maximum Energy possible
const MovingEnergyMult: float = 0.005 #Multiply this by the Force of the movement to obtain the Energy Cost
var Metabolism: float = MaxEnergyPossible*0.001		#Metabolism. Every step this value is deduced from Energy
var RechargingAreas: Array[Area2D] = []							#9 bones, 9 rigidbodies. If at least one rigidbodies is colliding with recharge zone, the robot recharges. this variable is tweaker in food-spawner

#movement
const MaxLinearVelocity: float = 500				#Maximum velocity that can be produced by a robot
var MaxForcePossible: int = 10   					#Maximum Movement Force possible
var AllowDirectionChange: bool = false				#Self explanatory
var StepsToChangeDirection: int = 0					#Counter to allow change in Movement Direction
var ChangeDirectionDelay: int = 50					#Delay to allow change in Movement Direction
@export var MovementDirection: Vector2 = Vector2(0,1)						#MovementDirection

#joining mechanics
const JoinThresold: float = 5						#if a collision happens while above this, they joint
####variables variavles

########
#not used yet/ideas
var Gene: Array[int] = [0]							#Gene Array
var MovementRules: Array[Vector2] = []				#Has the movement direction that will be taken after a collision happens in the corresponding bone
const ReproductionConst: float = 0.5   #Multiply this value by the max Energy value of created (not max Energy possible)
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
	#MovementDirection = Vector2(cos(deg_to_rad(randi_range(0,360))),sin(deg_to_rad(randi_range(0,360))))
	
	#gene_translation()
#---------------------------------------
func _process(delta: float) -> void:
	#$"SoftBody2D/Bone-4/Label".text = str(Energy)
	#$"SoftBody2D/Bone-4/Label2".text = str(RechargingAreas)
	pass
#---------------------------------------
func _physics_process(delta: float) -> void:	
	#Energy Economy
	if RechargingAreas:
		for eachArea in RechargingAreas:
			Energy += eachArea.get_parent().get_parent().GivenEnergy
	metabolize()
	#Alive, move!
	if Energy > 0:	
		#My movements
		if not AllowDirectionChange:
			StepsToChangeDirection += 1
			if StepsToChangeDirection > ChangeDirectionDelay:
				AllowDirectionChange = true
		#change_direction(get_random_direction())
		move_to_direction(MovementDirection,MaxForcePossible)

	#Ded, die: x-x 
	else:
		Global.Robots.erase(self)
		self.queue_free()
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
#---------------------------------------
func metabolize() -> void:
	Energy -= Metabolism
	if Energy < 0: Energy = 0 
#---------------------------------------
func change_direction(direction:Vector2) -> void:
	if AllowDirectionChange:
		MovementDirection = direction
		StepsToChangeDirection = 0
		AllowDirectionChange = false
#---------------------------------------
func move_to_direction(direction:Vector2, withForce:float) -> void:
		if not is_unit_vector(direction):
			direction = direction.normalized()
		Bones[CenterBoneIndex].apply_central_impulse(direction*withForce)
		Energy -= withForce*MovingEnergyMult
		
		##Limit velocity
		#if Bones[CenterBoneIndex].linear_velocity[0] > MaxLinearVelocity:
			#Bones[CenterBoneIndex].linear_velocity[0] = MaxLinearVelocity
			#
		#if Bones[CenterBoneIndex].linear_velocity[1] > MaxLinearVelocity:
			#Bones[CenterBoneIndex].linear_velocity[1] = MaxLinearVelocity
#---------------------------------------
func attach_bodies(myBone:RigidBody2D, otherBone: RigidBody2D) -> void:
	#print(myBone.position,otherBone.position)
	var joint:DampedSpringJoint2D = DampedSpringJoint2D.new()
	var spring:Line2D = Line2D.new()

	joint.name = "body-link"
	joint.position = myBone.global_position
	joint.node_a = myBone.get_path()
	joint.node_b = otherBone.get_path()
		
	joint.damping = JointDamping
	joint.stiffness = JointStiffness
	joint.length = JointLength
	joint.rest_length = JointRestLen
	joint.disable_collision = false
	
	myBone.Joined = true
	myBone.JoinedTo = otherBone
	myBone.get_parent().get_parent().add_child(joint)

	
	#joint1.position = point1
	#joint2.position = point2
	#
	#joint1.node_a = my_bone.get_path()
	#joint1.node_b = other_bone.get_path()
	#joint2.node_a = my_bone.get_path()
	#joint2.node_b = other_bone.get_path()
	#
	#joint1.scale = Vector2(1.2,1.2)
	#joint2.scale = Vector2(1.2,1.2)
	#
	#joint1.softness = 0.001
	#joint2.softness = 0.001
	#
	#my_bone.add_child(joint1)
	#my_bone.add_child(joint2)
#---------------------------------------
func is_unit_vector(vector:Vector2):
	return abs(vector.length_squared() - 1) < 0.001
#---------------------------------------
func get_direction_vector(fromA:Node,toB:Node) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector
#---------------------------------------
func get_random_direction() -> Vector2:
	var direction:Vector2 = Vector2(0,0)
	var collisionDirections = [get_direction_vector(Bones[4],Bones[0]), 
								get_direction_vector(Bones[4],Bones[1]),
								get_direction_vector(Bones[4],Bones[2]),
								get_direction_vector(Bones[4],Bones[3]),
								get_direction_vector(Bones[4],Bones[4]),
								get_direction_vector(Bones[4],Bones[5]),
								get_direction_vector(Bones[4],Bones[6]),
								get_direction_vector(Bones[4],Bones[7]),
								get_direction_vector(Bones[4],Bones[8])]
	return	-1*collisionDirections.pick_random()
#---------------------------------------
func _on_bone_collided(myBone:RigidBody2D,collider:Node):
	if collider.is_in_group("bone"):
		if (not collider.Joined) and (not myBone.Joined) and (Bones[CenterBoneIndex].linear_velocity.length() > JoinThresold):
			attach_bodies(myBone,collider)	
#---------------------------------------
func _on_charger_area_entered(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.append(area)
#---------------------------------------	
func _on_charger_area_exited(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.erase(area)
#---------------------------------------
func movement_rules(collision_point:Node):
	pass
func contract(bone:RigidBody2D, in_bone_direction:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,in_bone_direction)
	bone.apply_central_force(direction*withForce)

func _on_timer_timeout() -> void:
	pass
	#contract_blue(mult*maxForce)
	#contract_top(mult*maxForce)
	
		#$SoftBody2D.apply_impulse(Vector2(direction_x*power_x, direction_y*power_y))
#func _on_bone_collided_with_robot(my_bone:RigidBody2D,other_bone:RigidBody2D):
	#print(my_bone, other_bone)

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
		#print(Gene[bonesLimits[i][0]])
		pass


func _on_soft_body_2d_joint_removed(rigid_body_a: RefCounted, rigid_body_b: RefCounted) -> void:
	Global.Robots.erase(self)
	self.queue_free()
