extends Node2D
class_name Robot

## CONSTANTS
# BODY
var CenterBoneIndex: int = Global.BOTCenterBoneIndex					#Which is the bone in the center of the robot -> Force is applied on it
var ReplicationCoolDown:int = Global.BOTReplicationCoolDown 
var CriticalAge:int = Global.BOTCriticalAge
var MaxDeathProb:float = Global.BOTMaxDeathProb
var DeathOfAge:bool = Global.BOTDeathOfAge

# ENERGY ECONOMY
var MaxEnergyPossible: int = Global.BOTMaxEnergyPossible				#Maximum Energy possible
var MovingEnergyMult: float = Global.BOTMovingEnergyMult 				#Multiply this by the Force of the movement to obtain the Energy Cost
var Metabolism: float = Global.BOTMetabolism							#Metabolism. Every step this value is deduced from Energy
# MOVEMENT
var MaxForcePossible: float = Global.BOTMaxForcePossible   				#Maximum Movement Force possible
var ChangeDirectionDelay: float = Global.BOTChangeDirectionDelay		#Delay to allow change in Movement Direction
# JOINING MECHANICS
var JoinThresold: float = Global.BOTJoinThresold						#if a collision happens while above this, they joint

## VARIABLES
# BODY
var ReplicationCount:int = ReplicationCoolDown
var BonesThatCanJoin:Array = Global.BOTBonesThatCanJoin				#Which bones can join during the simulation
var MarkedForDeath = false
var Age:int = 0
var BornIn:int = 0
var Bones = []
var RobotID: String 													#Robot unique identifier
# ENERGY ECONOMY
var RechargingAreas: Array[Area2D] = []									#every Recharging area the charger node is colliding to.
var Energy: float = 0													#Current Energy
@export var EnergyBankIndex: int = 0											#which energy ban belongs to, 0=alone
# MOVEMENT
@export var MovementDirection: Vector2 = Vector2(0,0)					#MovementDirection
var AllowDirectionChange: bool = false									#Self explanatory
var StepsToChangeDirection: int = 0										#Counter to allow change in Movement Direction

### GENE/PARAMETERS
var MovementProbs:Dictionary = {"N":0.1,"S":0.1,"E":0.1,"W":0.1,"Z":0.6} #Green direction, Blue direction, Red direction, Yellow direction, (Zero movement)
var AttachProbability:Dictionary = {0:1, 1:0.8, 2:0.4, 3:0.6} # Qty of links robot has
var DettachProbability:Dictionary = {1:0.0001, 2:0.0001, 3:0.005, 4:0.5} # Qty of links robot has
var DeathLimit:int = 3 #If this number of links or more, die.
var LimitToReplicate:int = 0
var Gene: Array = [MovementProbs, AttachProbability, DettachProbability, DeathLimit, LimitToReplicate]						


# ADITIONAL VISUAL FEEDBACK
const EnergyBar:bool = true

########
#not used yet/ideas
var MovementRules: Array[Vector2] = []				#Has the movement direction that will be taken after a collision happens in the corresponding bone

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
	$"SoftBody2D/Bone-4/Label2".text = str(get_current_energy())
#---------------------------------------
func _physics_process(_delta: float) -> void:	
	if not(MarkedForDeath):
		Age += 1
		#Check deaths:
		if DeathOfAge:
			check_die_of_age()
		if get_joinedTo_number() >= DeathLimit:
			die(2)		
		if get_current_energy() <= 0:
			die(0)

		#Self-replication cooldown
		if not(MarkedForDeath):

			#Eat if possible
			if RechargingAreas and (get_current_energy() < get_maximum_energy()):
				for eachArea in RechargingAreas:
					sum_to_energy(eachArea.get_parent().get_parent().give_energy())

			#Consume to stay alive
			metabolize()

			#Replication if possible
			if ReplicationCount > 0:
				ReplicationCount -= 1
			if (get_joinedTo_number() >= LimitToReplicate) and (ReplicationCount==0):
				self_replicate()
				
			#Move if possible
			if not AllowDirectionChange:
				StepsToChangeDirection += 1
				if StepsToChangeDirection > ChangeDirectionDelay:
					AllowDirectionChange = true
			change_direction(get_direction())
			move_to_direction(MovementDirection,MaxForcePossible)

			#check if is to break joints
			check_joints()
		
			
	# print(""+str(name)+" "+str(EnergyBankIndex))
#---------------------------------------
# Actions
#---------------------------------------
func self_replicate() -> void:
	var descendent:Robot = Global.ROBOT.instantiate()
	var new_gene:Array = []

	if randf() <= Global.MutationRate:
		new_gene = Global.mutate_gene(Gene)
	else: 
		new_gene = Gene.duplicate(true)

	descendent.initialize_gene(new_gene)
	descendent.global_position = get_replication_position()
	ReplicationCount = ReplicationCoolDown
	get_parent().add_child(descendent)

	LogManager.log_bot(descendent, "Self-Replication of "+str(RobotID))
	LogManager.log_replication_event(self,descendent)
#---------------------------------------
func get_replication_position() -> Vector2:
	var grads = deg_to_rad(randi_range(0,360))
	var replicant_position:Vector2 = Bones[CenterBoneIndex].global_position + Vector2(cos(grads)*100,sin(grads)*100)
	while (position[0]>Global.WorldSize[0]-20) or (position[1]>Global.WorldSize[1]-20):
		replicant_position = Bones[CenterBoneIndex].global_position + Vector2(cos(grads)*100,sin(grads)*100)
	return replicant_position
#---------------------------------------
func metabolize() -> void:
	sum_to_energy(-Metabolism)
#---------------------------------------
func die(reason:int) -> void:
	#ways to die: 0 = out of energy / 1 = joint 4 broke / 2 = death rule / 3 = death of age
	if (reason==3): #death of age
		LogManager.log_bot_snapshot(self,"Death-Age")
		LogManager.log_event("[event] Death by Age "+str(RobotID))
		LogManager.log_death_event(self,"Died of Age")
		EventManager.add_bot_to_die(self)

	if (reason==2): #death rule
		LogManager.log_bot_snapshot(self,"Death-rule")
		LogManager.log_event("[event] Death by RULE "+str(RobotID))
		LogManager.log_death_event(self,"Rule (Linked to "+str(DeathLimit)+" bots")
		EventManager.add_bot_to_die(self)

	elif (reason==1): #central bone-joint broke
		# Global.death(self)
		LogManager.log_bot_snapshot(self,"Death-nucleos break")
		LogManager.log_event("[event] Death by nucleos break "+str(RobotID))
		LogManager.log_death_event(self,"Bot broke")

		EventManager.add_bot_to_die(self)
		# if Global.StopStep<1: Global.StopStep = Global.Step+2

	elif (reason==0): #out of energy
		if (EnergyBankIndex > 0):
			for cell in Global.BotsAtEnergyBank[EnergyBankIndex]:
				EventManager.add_bot_to_die(cell)
				LogManager.log_bot_snapshot(cell,"Death-no energy")
				LogManager.log_event("[event] Death by no energy "+str(RobotID))
				LogManager.log_death_event(self,"No energy on EnergyBank")

				# Global.death(cell)
		else: 
			EventManager.add_bot_to_die(self)
			LogManager.log_bot_snapshot(self,"Death-no energy")
			LogManager.log_event("[event] Death by no energy "+str(RobotID))
			LogManager.log_death_event(self,"No energy")
#---------------------------------------
func change_direction(direction:Vector2) -> void:
	if AllowDirectionChange:
		MovementDirection = direction
		StepsToChangeDirection = 0
		AllowDirectionChange = false
#---------------------------------------
func move_to_direction(direction:Vector2, withForce:float) -> void:
		if not Global.is_unit_vector(direction):
			direction = direction.normalized()
		if is_instance_valid(Bones[CenterBoneIndex]) and direction != Vector2(0,0):
			Bones[CenterBoneIndex].apply_central_impulse(direction*withForce)
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
#---------------------------------------
func check_die_of_age() -> void:
	var a:float = 0.000001 #influences death prob before critical age
	var b:float = 0.8 #influences how steep curve is near critical age, but also how long
	var c:float = 1 #influences how steep curve is near critical age

	var probToDie:float = Age*a + pow(b,-c*(Age-CriticalAge*0.8))
	if randf() <= probToDie:
		die(3)
#---------------------------------------
func get_maximum_energy() -> float:
	if EnergyBankIndex > 0:
		return Global.BotsAtEnergyBank[EnergyBankIndex].size()*MaxEnergyPossible
	else:
		return MaxEnergyPossible
#---------------------------------------
func get_current_energy() -> float:
	if EnergyBankIndex > 0:
		return Global.EnergyBank[EnergyBankIndex]
	else:
		return Energy
#---------------------------------------
func create_energy_bar() -> void:
	var energyBar:ColorRect = ColorRect.new()
	var squareSize:Vector2 = Vector2(5,5)
	energyBar.position = Bones[CenterBoneIndex].position-Vector2(12.5,12.5)-squareSize/2
	energyBar.size = squareSize
	energyBar.color = Color(0,255,0)
	energyBar.name = "energy-bar"
	Bones[CenterBoneIndex].add_child(energyBar)
#---------------------------------------
func update_energy_bar() -> void:
	var energyBar:ColorRect = Bones[CenterBoneIndex].get_node_or_null("energy-bar")
	if energyBar: 
		var percEnergy:float = get_current_energy()/get_maximum_energy()
		energyBar.color = lerp(Color.RED, Color.GREEN, percEnergy)
#---------------------------------------
# Tools
#---------------------------------------
#--------------------------------------
func initialize_gene(gene:Array) -> void:
	Gene = gene
	MovementProbs = Gene[0]
	AttachProbability = Gene[1]
	DettachProbability = Gene[2]
	DeathLimit = Gene[3]
	LimitToReplicate = Gene[4]
#---------------------------------------
func start_robot() -> void:
	Global.QtyRobotsCreated += 1
	Global.QtyRobotsAlive += 1
	self.name = ("Bot"+str(Global.QtyRobotsCreated))
	RobotID = self.name
	self.BornIn = Global.Step

	#Start variables
	Energy = MaxEnergyPossible
	Global.BotsAtEnergyBank[EnergyBankIndex].append(self)
	#Builds the ID to robot and adds robot and its Bones to this group
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

	for bone in BonesThatCanJoin:
		Bones[bone].CanJoin = true
#---------------------------------------
func get_joinedTo_number() -> int:
	#Returns the number of bots self is joined to
	var output:int = 0
	for bone in BonesThatCanJoin:
		if Bones[bone].Joined:
			output += 1
	return output
#---------------------------------------
func get_direction() -> Vector2:
	var directionCode:String = Global.weighted_choice(MovementProbs)
	var movementTranslationDict:Dictionary = {"N": Vector2(0,-1),
									"S": Vector2(0,1),
									"E": Vector2(1,0),
									"W": Vector2(-1,0),
									"Z": Vector2(0,0)}
	return movementTranslationDict[directionCode]
#---------------------------------------
func is_alone() -> bool:
	for i in range(Bones.size()):
		if Bones[i].Joined: 
			return false
	return true
#---------------------------------------
func check_joints() -> void:
	for bone in Bones:
		var jointLine:Line2D = get_node_or_null(str(str(bone.get_path())+"/jointline"))
		if bone.Joined and is_instance_valid(bone.JoinedTo):
			
			var otherBot = bone.JoinedTo.get_parent().get_parent()
			# var jointAngleDif = abs(rad_to_deg(MovementDirection.angle_to(bone.JointDirection)))
			# var velAngleDif = abs(rad_to_deg(MovementDirection.angle_to(otherBot.MovementDirection)))
			var rand:float = randf()
			if rand <= DettachProbability[get_joinedTo_number()]:
			# if (jointAngleDif > (180-bone.AngleVariationToBreakJoint)) and (velAngleDif > (180-bone.AngleVariationToBreakJoint)):# and (Bones[CenterBoneIndex].linear_velocity.length() > JoinThresold):
				if not jointLine: jointLine = get_node_or_null(str(str(bone.JoinedTo.get_path())+"/jointline"))
				# EventManager.add_joints_to_break_queue(self,otherBot,bone,jointLine)
				LogManager.log_event("\n [event][check_joints] Break a Joint, {0}, {1} x {2}, {3}".format([self.RobotID, bone.name, otherBot.RobotID, bone.JoinedTo.name]))				
				EventManager.resolve_break_joint(self,otherBot,bone,jointLine)
				LogManager.log_break_event(self,otherBot)
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
	if myBone == Bones[CenterBoneIndex]:
		die(1)
	if collider.is_in_group("bone")and(myBone.CanJoin):
		var rand:float = randf()
		var joinedToNumber = get_joinedTo_number()
		if joinedToNumber < BonesThatCanJoin.size():
			var passed_velocity_check: = true
			if Global.BOTUsingJoinThresold:
				if not(Bones[CenterBoneIndex].linear_velocity.length() > JoinThresold):
					passed_velocity_check = false
			if (passed_velocity_check) and (rand <= AttachProbability[joinedToNumber]) and (collider.CanJoin) and (not collider.Joined) and (not myBone.Joined):
				# EventManager.add_joints_to_create_queue(myBone,collider)
				LogManager.log_event("\n [event][bone_collisions] " +str(self.RobotID)+","+str(myBone.name)+" x "+str(collider.BoneOf)+","+str(collider.name))
				EventManager.resolve_create_joint(myBone,collider)
				LogManager.log_join_event(self,collider.get_parent().get_parent())
				# EventManager.attach_bodies(myBone,  collider)
				# EnergyBankManager.joint_made(myBone,collider)
#---------------------------------------
func _on_charger_area_entered(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.append(area)	
#---------------------------------------
func _on_charger_area_exited(area: Area2D) -> void:
	if (area.is_in_group("recharge-area")):
		RechargingAreas.erase(area)
#---------------------------------------
func _on_soft_body_2d_joint_removed(_rigid_body_a: RefCounted, _rigid_body_b: RefCounted) -> void:
	die(1)
	# if (_rigid_body_a.rigidbody.name=="Bone-4") or (_rigid_body_b.rigidbody.name=="Bone-4"):
	# 	die(1)
#---------------------------------------
func _input(event):
	if event.is_action_released("ui_down"):
		MovementDirection *= Vector2(x_direction_multiplier,1)		
#---------------------------------------
