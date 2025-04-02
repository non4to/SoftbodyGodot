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
const MaxForcePossible: int = Global.BOTMaxForcePossible   				#Maximum Movement Force possible
const ChangeDirectionDelay: float = Global.BOTChangeDirectionDelay		#Delay to allow change in Movement Direction
# JOINING MECHANICS
const JoinThresold: float = Global.BOTJoinThresold						#if a collision happens while above this, they joint

## VARIABLES
# BODY
var Age:int = 0
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
# JOINING MECHANICS
var Attached: bool = false												#Identifies if this robot is attached to any other or not.
var GroupIndex: int														#Group index this robot belongs to. All attached robots occupy same group index. if 0 = alone
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

## Genes: velocity value, Energy
## 4 sensors: one of each side.

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	pass
	#Gene
	#[MaxEnergy,Metabolism]
	#self.Gene = Gene
	#if self.Gene==9:
		#self.Gene = 0b01011010101010101101110001110101010101111010
#---------------------------------------
func _ready() -> void:
	start_robot() #ID to the robot and its Bones
	if EnergyBar: create_energy_bar()
	# MovementDirection = Vector2(cos(deg_to_rad(randi_range(0,360))),sin(deg_to_rad(randi_range(0,360))))
	
	#gene_translation()
#---------------------------------------
@warning_ignore("UNUSED_PARAMETER")
func _process(delta: float) -> void:
	if EnergyBar: update_energy_bar()

	# print(str(self.name)+": "+str(self.Energy))
	# if EnergyBankIndex != oldEnergyBankIndex:
	# 	print(str(self.name)+"OLD: "+str(self.oldEnergyBankIndex))
	# 	oldEnergyBankIndex = EnergyBankIndex
	# 	print(str(self.name)+"OLD: "+str(self.EnergyBankIndex))
	
	#$"SoftBody2D/Bone-4/Label".text = str(Bones[CenterBoneIndex].linear_velocity[0])
	#$"SoftBody2D/Bone-4/Label2".text = str(Bones[CenterBoneIndex].linear_velocity[1])	
	pass
#---------------------------------------
@warning_ignore("UNUSED_PARAMETER")
func _physics_process(delta: float) -> void:	
	Age += 1
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
	#Ded, die: x-x 
	else:
		die()
#---------------------------------------
# Actions
func metabolize() -> void:
	sum_to_energy(-Metabolism)
func die() -> void:
	if EnergyBankIndex > 0:
		for cell in Global.BotsAtEnergyBank[EnergyBankIndex]:
			death(cell)
	else: death(self)
func change_direction(direction:Vector2) -> void:
	if AllowDirectionChange:
		MovementDirection = direction
		StepsToChangeDirection = 0
		AllowDirectionChange = false
func move_to_direction(direction:Vector2, withForce:float) -> void:
		if not is_unit_vector(direction):
			direction = direction.normalized()
		Bones[CenterBoneIndex].apply_central_impulse(direction*withForce)
		#$SoftBody2D.apply_impulse(direction*withForce)
		sum_to_energy(-1*withForce*MovingEnergyMult)


func death(bot:Robot) -> void:
	for bone in bot.Bones:
		if (bone.Joined) and (is_instance_valid(bone.JoinedTo)):
			var jointLine:Line2D = bone.JoinedTo.get_node_or_null("joint")
			if jointLine: jointLine.queue_free()
		for joint in bone.RelatedJoints:
			if is_instance_valid(joint):
				joint.queue_free()
	Global.BotsAtEnergyBank[bot.EnergyBankIndex].erase(bot)
	if (bot.EnergyBankIndex>0)and(Global.BotsAtEnergyBank[bot.EnergyBankIndex].size() < 1):
		Global.FreeBanks.append(EnergyBankIndex)
	# print(Global.BotsAtEnergyBank)
	Global.Robots.erase(bot)
	bot.queue_free()
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
func move_to_energy_bank(bot:Robot, joiningBank:int) -> void:
	var leavingBank:int = bot.EnergyBankIndex
	bot.EnergyBankIndex = joiningBank
	if not (joiningBank in Global.EnergyBank):
		Global.EnergyBank[joiningBank] = 0
		Global.BotsAtEnergyBank[joiningBank] = []

	#LeavingBankEnergyAdjust
	var proportionalEnergy = Global.EnergyBank[leavingBank] / Global.BotsAtEnergyBank[leavingBank].size()
	if leavingBank > 0: 
		Global.EnergyBank[leavingBank] -= proportionalEnergy
		bot.Energy = proportionalEnergy
	Global.BotsAtEnergyBank[leavingBank].erase(bot)
	#JoiningBankEnergyAdjust
	if joiningBank > 0: 
		Global.EnergyBank[joiningBank] += bot.Energy
	Global.BotsAtEnergyBank[joiningBank].append(bot)
	#BankChecks
	if (leavingBank>0)and(Global.BotsAtEnergyBank[leavingBank].size()==0):
		Global.EnergyBank[leavingBank] = 0
		Global.FreeBanks.append(leavingBank)
#---------------------------------------
# Tools
func start_robot() -> void:
	#Start variables
	Energy = MaxEnergyPossible
	Global.BotsAtEnergyBank[EnergyBankIndex].append(self)
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
			bone.connect("joint_broke", _on_joint_break)

	var bonesThatCanotJoin:Array = [0,2,4,6,8]
	for bone in bonesThatCanotJoin:
		Bones[bone].CanJoin = false

func is_unit_vector(vector:Vector2):
	return abs(vector.length_squared() - 1) < 0.001

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
func is_alone(robot:Robot) -> bool:
	print(robot.name)
	for i in range(robot.Bones.size()):
		print(i,Bones[i].Joined)
		if Bones[i].Joined: 
			return false
	return true
func contract(bone:RigidBody2D, inBoneDirection:RigidBody2D, withForce:float) -> void:
	var direction = self.Global.get_direction_vector(bone,inBoneDirection)
	bone.apply_central_impulse(direction*withForce)
func assign_energy_bank(botB: Robot):
	var botA:Robot = self
	if (botA.EnergyBankIndex > 0): 
	#A(in)
		pass

		if (botB.EnergyBankIndex > 0): 
		#A(in)B(in)
			pass

		else: 
		#A(in)B(out)
			pass

	else: 
	#A(out)
		pass

		if (botB.EnergyBankIndex > 0):
			pass
		#A(out)B(in)
			# move_to_energy_bank(botA,(botB.EnergyBankIndex))
		else: 
		#A(out)B(out)
			var newBank:int = 0
			if Global.FreeBanks.size() > 0:
				newBank = Global.FreeBanks.pop_front()
			else:
				newBank = Global.EnergyBank.keys().size()

			Global.EnergyBank[newBank] = 0
			Global.BotsAtEnergyBank[newBank] = []

			move_to_energy_bank(botA,newBank)
			move_to_energy_bank(botB,newBank)			
#---------------------------------------
# Signals
func _on_bone_collided(myBone:RigidBody2D,collider:Node):
	if collider.is_in_group("bone")and(myBone.CanJoin):
		if (collider.CanJoin) and (not collider.Joined) and (not myBone.Joined) and (Bones[CenterBoneIndex].linear_velocity.length() > JoinThresold):
			AttachmentManager.attach_bodies(myBone,  collider)

func _on_joint_break(_myBone:RigidBody2D,otherBot:Robot):
	if EnergyBankIndex == 0: push_error("This block has EnergyBankIndex=0 but just had a joint broken")
	print(self.name, otherBot.name)
	if is_alone(self):
		move_to_energy_bank(self,0)

	print(otherBot.name)
	if is_alone(otherBot):
		move_to_energy_bank(otherBot,0)

func _on_charger_area_entered(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.append(area)	
func _on_charger_area_exited(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.erase(area)
func _on_soft_body_2d_joint_removed(rigid_body_a: RefCounted, rigid_body_b: RefCounted) -> void:
	if (rigid_body_a.rigidbody.name=="Bone-4") or (rigid_body_b.rigidbody.name=="Bone-4"):
		die()
#---------------------------------------
func _input(event):
	if event.is_action_released("ui_down"):
		MovementDirection *= Vector2(x_direction_multiplier,1)
