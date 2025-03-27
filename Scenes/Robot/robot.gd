extends Node2D

#body
var Bones = []
var RobotID: String 								#Robot unique identifier
const CenterBoneIndex: int = 4      #Which is the bone in the center of the robot -> Force is applied on it

#energy economy
var Energy: float = 0								#Current Energy
const MaxEnergyPossible: int = 9999999999  #Maximum Energy possible
const MovingEnergyMult: float = 0.005 #Multiply this by the Force of the movement to obtain the Energy Cost
var Metabolism: float = MaxEnergyPossible*0.001		#Metabolism. Every step this value is deduced from Energy
var RechargingAreas: Array[Area2D] = []							#9 bones, 9 rigidbodies. If at least one rigidbodies is colliding with recharge zone, the robot recharges. this variable is tweaker in food-spawner

#movement
const MaxLinearVelocity: float = 500				#Maximum velocity that can be produced by a robot
@export var MaxForcePossible: int = 50   					#Maximum Movement Force possible
var AllowDirectionChange: bool = false				#Self explanatory
var StepsToChangeDirection: int = 0					#Counter to allow change in Movement Direction
var ChangeDirectionDelay: int = 50					#Delay to allow change in Movement Direction
@export var MovementDirection: Vector2 = Vector2(1,0)						#MovementDirection

#joining mechanics
const JoinThresold: float = 150						#if a collision happens while above this, they joint
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
	MovementDirection = Vector2(cos(deg_to_rad(randi_range(0,360))),sin(deg_to_rad(randi_range(0,360))))
	
	#gene_translation()
#---------------------------------------
func _process(delta: float) -> void:
	
	#$"SoftBody2D/Bone-4/Label".text = str(Bones[CenterBoneIndex].linear_velocity[0])
	#$"SoftBody2D/Bone-4/Label2".text = str(Bones[CenterBoneIndex].linear_velocity[1])
	
	
	
	pass
#---------------------------------------
func check_unjoint() -> void:
	pass
			
		#if Bones[CenterBoneIndex].linear_velocity.length > Bones[i].ToUnjoint.length:
			#print(Bones[i],"WOW FAST!")
		
		
		
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
		change_direction(get_random_direction())
		move_to_direction(MovementDirection,MaxForcePossible)

	#Ded, die: x-x 
	else:
		die()
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
			bone.connect("bone_collided", _on_bone_collided)
#---------------------------------------
#---------------------------------------
func metabolize() -> void:
	Energy -= Metabolism
	if Energy < 0: Energy = 0 
#---------------------------------------
func die() -> void:
	for bone in Bones:
		if (bone.Joined) and (is_instance_valid(bone.JoinedTo)):
			var jointLine:Line2D = bone.JoinedTo.get_node_or_null("joint")
			if jointLine: jointLine.queue_free()
		for joint in bone.RelatedJoints:
			if is_instance_valid(joint):
				joint.queue_free()
	Global.Robots.erase(self)
	self.queue_free()

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
		#$SoftBody2D.apply_impulse(direction*withForce)
		Energy -= withForce*MovingEnergyMult
		
		##Limit velocity
		#if Bones[CenterBoneIndex].linear_velocity[0] > MaxLinearVelocity:
			#Bones[CenterBoneIndex].linear_velocity[0] = MaxLinearVelocity
			#
		#if Bones[CenterBoneIndex].linear_velocity[1] > MaxLinearVelocity:
			#Bones[CenterBoneIndex].linear_velocity[1] = MaxLinearVelocity
#---------------------------------------
func attach_bodies(myBone:RigidBody2D, otherBone: RigidBody2D) -> void:	
	var joint1: PinJoint2D = PinJoint2D.new()
	var joint2: PinJoint2D = PinJoint2D.new()

	joint1.position = Vector2(0,0)
	joint1.node_a = myBone.get_path()
	joint1.node_b = otherBone.get_path()
	joint1.softness = 0.001
	joint1.disable_collision =false
	joint1.name = "body-link"
	myBone.Joined = true
	myBone.JoinedTo = otherBone
	myBone.JointDirection = get_direction_vector(myBone,otherBone)
	myBone.add_child(joint1)
	
	
	joint2.position = Vector2(0,0)
	joint2.node_a = otherBone.get_path()
	joint2.node_b = myBone.get_path()
	joint2.softness = 0.001
	joint2.disable_collision =false
	joint2.name = "body-link"
	otherBone.Joined = true
	otherBone.JoinedTo = myBone
	otherBone.JointDirection = get_direction_vector(otherBone,myBone)
	otherBone.add_child(joint2)
	
	myBone.RelatedJoints.append(joint1)
	myBone.RelatedJoints.append(joint2)
	otherBone.RelatedJoints.append(joint1)
	otherBone.RelatedJoints.append(joint2)
	
	var jointLine:Line2D = Line2D.new()
	jointLine.name = "joint"
	jointLine.add_point(myBone.global_position/100,0)
	jointLine.add_point(otherBone.global_position/100,1)
	jointLine.default_color = Color(255,255,255)
	jointLine.width = 3
	jointLine.z_index = -1
	myBone.add_child(jointLine)
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
			#print(Bones[CenterBoneIndex].linear_velocity.length())
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
func _on_soft_body_2d_joint_removed(rigid_body_a: RefCounted, rigid_body_b: RefCounted) -> void:
	if (rigid_body_a.rigidbody.name=="Bone-4") or (rigid_body_b.rigidbody.name=="Bone-4"):
		die()
#---------------------------------------
func movement_rules(collision_point:Node):
	pass
func contract(bone:RigidBody2D, inBoneDirection:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,inBoneDirection)
	bone.apply_central_impulse(direction*withForce)
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
