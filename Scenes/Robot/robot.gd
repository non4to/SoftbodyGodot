extends Node2D
class_name Robot
## CONSTANTS
# BODY
const CenterBoneIndex: int = Global.BOTCenterBoneIndex					#Which is the bone in the center of the robot -> Force is applied on it
# ENERGY ECONOMY
const MaxEnergyPossible: int = Global.BOTMaxEnergyPossible				#Maximum Energy possible
const MovingEnergyMult: float = Global.BOTMovingEnergyMult 				#Multiply this by the Force of the movement to obtain the Energy Cost
const Metabolism: float = Global.BOTMetabolism							#Metabolism. Every step this value is deduced from Energy
# MOVEMENT
const MaxForcePossible: float = Global.BOTMaxForcePossible   				#Maximum Movement Force possible
const ChangeDirectionDelay: float = Global.BOTChangeDirectionDelay		#Delay to allow change in Movement Direction
# JOINING MECHANICS
const JoinThresold: float = Global.BOTJoinThresold						#if a collision happens while above this, they joint

## VARIABLES
# BODY
var MarkedForDeath = true
var Age:int = 0
var BornIn:int = 0
var Bones = []
var RobotID: String 													#Robot unique identifier
# ENERGY ECONOMY
var RechargingAreas: Array[Area2D] = []									#every Recharging area the charger node is colliding to.
var Energy: float = 0													#Current Energy
@export var EnergyBankIndex: int = 0											#which energy ban belongs to, 0=alone
# MOVEMENT
@export var MovementDirection: Vector2 = Vector2(1,0)					#MovementDirection
var AllowDirectionChange: bool = false									#Self explanatory
var StepsToChangeDirection: int = 0										#Counter to allow change in Movement Direction

# ADITIONAL VISUAL FEEDBACK
const EnergyBar:bool = true

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
var is_bigger=false
var oldEnergyBankIndex:int = EnergyBankIndex

@export var x_direction_multiplier:float = -1

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	pass
#---------------------------------------
func _ready() -> void:
	start_robot() #ID to the robot and its Bones
	if EnergyBar: create_energy_bar()
	# MovementDirection = Vector2(cos(deg_to_rad(randi_range(0,360))),sin(deg_to_rad(randi_range(0,360))))
	
#---------------------------------------
func _process(_delta: float) -> void:
	if EnergyBar: update_energy_bar()
	if RobotID: pass
		# $"SoftBody2D/Bone-4/Label".text = RobotID
#---------------------------------------
func _physics_process(_delta: float) -> void:	
	Age += 1
	if not MarkedForDeath:
		#Energy Economy
		if RechargingAreas:
			for eachArea in RechargingAreas:
				sum_to_energy(eachArea.get_parent().get_parent().GivenEnergy)
		metabolize()
		#Alive, move!
		if get_current_energy() > 0:	
			#My movements
			if not AllowDirectionChange:
				StepsToChangeDirection += 1
				if StepsToChangeDirection > ChangeDirectionDelay:
					AllowDirectionChange = true
			change_direction(get_random_direction_fromNSWE())
			move_to_direction(MovementDirection,MaxForcePossible)
			check_joints()
		#Ded, die: x-x 
		else:
			die(0)

		LogManager.log_frame_data(Global.Step,"step",self)
		# print(""+str(name)+" "+str(EnergyBankIndex))
#---------------------------------------
# Actions
func metabolize() -> void:
	sum_to_energy(-Metabolism)

func die(reason:int) -> void:
	#ways to die: 0 = out of energy / 1 = joint 4 broke
	if (reason==1): #central bone-joint broke
		Global.death(self)
		LogManager.log_frame_data(Global.Step,"Death-nucleos break",self)
		# if Global.StopStep<1: Global.StopStep = Global.Step+2

	elif (reason==0): #out of energy
		if (EnergyBankIndex > 0):
			for cell in Global.BotsAtEnergyBank[EnergyBankIndex]:
				LogManager.log_frame_data(Global.Step,"Death-no energy",cell)
				Global.death(cell)
		else: Global.death(self)

func change_direction(direction:Vector2) -> void:
	if AllowDirectionChange:
		MovementDirection = direction
		StepsToChangeDirection = 0
		AllowDirectionChange = false
		
func move_to_direction(direction:Vector2, withForce:float) -> void:
		if not Global.is_unit_vector(direction):
			direction = direction.normalized()
		if is_instance_valid(Bones[CenterBoneIndex]):
			Bones[CenterBoneIndex].apply_central_impulse(direction*withForce)
			#$SoftBody2D.apply_impulse(direction*withForce)
			sum_to_energy(-1*withForce*MovingEnergyMult)

#---------------------------------------
# Energy operations
func sum_to_energy(value:float) -> void:
	if EnergyBankIndex > 0:
		Global.EnergyBank[EnergyBankIndex] += value
		if Global.EnergyBank[EnergyBankIndex] < 0: 
			Global.EnergyBank[EnergyBankIndex] = 0
		elif Global.EnergyBank[EnergyBankIndex] > get_maximum_energy():
			Global.EnergyBank[EnergyBankIndex] = get_maximum_energy()
	else:
		Energy += value	
		if Energy < 0: Energy = 0
		elif Energy > MaxEnergyPossible: Energy = MaxEnergyPossible

func get_maximum_energy() -> float:
	if EnergyBankIndex > 0:
		return Global.BotsAtEnergyBank[EnergyBankIndex].size()*MaxEnergyPossible
	else:
		return MaxEnergyPossible

func get_current_energy() -> float:
	if EnergyBankIndex > 0:
		return Global.EnergyBank[EnergyBankIndex]
	else:
		return Energy

func create_energy_bar() -> void:
	var energyBar:ColorRect = ColorRect.new()
	var squareSize:Vector2 = Vector2(5,5)
	energyBar.position = Bones[CenterBoneIndex].position-Vector2(12.5,12.5)-squareSize/2
	energyBar.size = squareSize
	energyBar.color = Color(0,255,0)
	energyBar.name = "energy-bar"
	Bones[CenterBoneIndex].add_child(energyBar)

func update_energy_bar() -> void:
	var energyBar:ColorRect = Bones[CenterBoneIndex].get_node_or_null("energy-bar")
	if energyBar: 
		var percEnergy:float = get_current_energy()/get_maximum_energy()
		energyBar.color = lerp(Color.BLACK, Color.RED, percEnergy)
#---------------------------------------
# Tools
func start_robot() -> void:
	Global.QtyRobotsCreated += 1
	Global.QtyRobotsAlive += 1
	self.name = ("Bot"+str(Global.QtyRobotsCreated))
	self.BornIn = Global.Step
	#Start variables
	Energy = MaxEnergyPossible
	Global.BotsAtEnergyBank[EnergyBankIndex].append(self)
	#Builds an ID to robot and adds robot and its Bones to this group
	RobotID = self.name#"id_" + str(get_instance_id())
	add_to_group("robot")
	add_to_group(RobotID)
	
	for bone in get_node("SoftBody2D").get_children():
		if bone.is_class("RigidBody2D") and ("Bone" in bone.name):
			Bones.append(bone)	
			bone.add_to_group("bone")
			bone.add_to_group(RobotID)
			bone.connect("bone_collided", _on_bone_collided)
			bone.BoneOf=RobotID
			# bone.connect("joint_broke", _on_joint_break)

	var bonesThatCanotJoin:Array = [4]
	for bone in bonesThatCanotJoin:
		Bones[bone].CanJoin = false

func get_random_direction() -> Vector2:
	var collisionDirections = [Global.get_direction_vector(Bones[4],Bones[0]), 
								Global.get_direction_vector(Bones[4],Bones[1]),
								Global.get_direction_vector(Bones[4],Bones[2]),
								Global.get_direction_vector(Bones[4],Bones[3]),
								Global.get_direction_vector(Bones[4],Bones[4]),
								Global.get_direction_vector(Bones[4],Bones[5]),
								Global.get_direction_vector(Bones[4],Bones[6]),
								Global.get_direction_vector(Bones[4],Bones[7]),
								Global.get_direction_vector(Bones[4],Bones[8]),
								]
	return	-1*collisionDirections.pick_random()

func get_random_direction_fromNSWE() -> Vector2:
	var collisionDirections = [ 
								Global.get_direction_vector(Bones[4],Bones[1]),
								Global.get_direction_vector(Bones[4],Bones[3]),
								Global.get_direction_vector(Bones[4],Bones[5]),
								Global.get_direction_vector(Bones[4],Bones[7]),
								]
	return	-1*collisionDirections.pick_random()

func is_alone() -> bool:
	for i in range(Bones.size()):
		if Bones[i].Joined: 
			return false
	return true

func check_joints() -> void:
	for bone in Bones:
		var jointLine:Line2D = get_node_or_null(str(str(bone.get_path())+"/jointline"))
		if bone.Joined and is_instance_valid(bone.JoinedTo):
			var otherBot = bone.JoinedTo.get_parent().get_parent()
			var jointAngleDif = abs(rad_to_deg(MovementDirection.angle_to(bone.JointDirection)))
			var velAngleDif = abs(rad_to_deg(MovementDirection.angle_to(otherBot.MovementDirection)))
			if (jointAngleDif > (180-bone.AngleVariationToBreakJoint)) and (velAngleDif > (180-bone.AngleVariationToBreakJoint)):
				if not jointLine: jointLine = get_node_or_null(str(str(bone.JoinedTo.get_path())+"/jointline"))
				LogManager.log_event(Global.Step,"[check_joints] de-attachment",self.RobotID,bone.name,otherBot.name,bone.JoinedTo.name)
				EventManager.add_joints_to_break_queue(self,otherBot,bone,jointLine)
				# EnergyBankManager.joint_broke(self,otherBot)
				# EventManager.break_joint(bone,jointLine)	
			else:
				if jointLine:	
					var point1 = jointLine.to_local(bone.global_position)
					var point2 = jointLine.to_local(bone.JoinedTo.global_position)
					jointLine.set_point_position(0, point1)
					jointLine.set_point_position(1, point2)
		else:
			if jointLine:
				LogManager.print_state()
				print(bone.Joined)
				print(bone.JoinedTo)
				print(bone,jointLine)
				LogManager.save_log()
				assert(false, str(self)+" has a jointLine but is not Joined or has a JoinedTo")
#---------------------------------------
# Signals
func _on_bone_collided(myBone:RigidBody2D,collider:Node):
	if collider.is_in_group("bone")and(myBone.CanJoin):
		if (collider.CanJoin) and (not collider.Joined) and (not myBone.Joined) and (Bones[CenterBoneIndex].linear_velocity.length() > JoinThresold):
			LogManager.log_event(Global.Step,"[bone_collisions] attachment",self.RobotID,myBone.name,collider.BoneOf,collider.name)
			EventManager.add_joints_to_create_queue(myBone,collider)
			# EventManager.attach_bodies(myBone,  collider)
			# EnergyBankManager.joint_made(myBone,collider)

func _on_charger_area_entered(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.append(area)	

func _on_charger_area_exited(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.erase(area)

func _on_soft_body_2d_joint_removed(rigid_body_a: RefCounted, rigid_body_b: RefCounted) -> void:
	if (rigid_body_a.rigidbody.name=="Bone-4") or (rigid_body_b.rigidbody.name=="Bone-4"):
		die(1)
#---------------------------------------
func _input(event):
	if event.is_action_released("ui_down"):
		MovementDirection *= Vector2(x_direction_multiplier,1)
