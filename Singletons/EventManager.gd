extends Node
const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.tscn")

var JointsToBreak:Array = []
var JointsToCreate:Array = []
var BotsToDie:Array = []

func _physics_process(_delta: float) -> void:
	call_deferred("resolve_joints_to_create_queue")
	call_deferred("resolve_joints_to_break_queue")
	call_deferred("resolve_deaths")
#--------------------------------------
func attach_bodies(boneA:Bone, boneB: Bone) -> void:	
	var joint1: PinJoint2D = PinJoint2D.new()
	var joint2: PinJoint2D = PinJoint2D.new()

	joint1.position = Vector2(0,0)
	joint1.node_a = boneA.get_path()
	joint1.node_b = boneB.get_path()
	joint1.softness = 0.001
	joint1.disable_collision =false
	joint1.name = "body-link"
	boneA.Joined = true
	boneA.JoinedTo = boneB
	boneA.JointDirection = Global.get_direction_vector(boneA,boneB)
	boneA.add_child(joint1)
	
	joint2.position = Vector2(0,0)
	joint2.node_a = boneB.get_path()
	joint2.node_b = boneA.get_path()
	joint2.softness = 0.001
	joint2.disable_collision =false
	joint2.name = "body-link"
	boneB.Joined = true
	boneB.JoinedTo = boneA
	boneB.JointDirection = Global.get_direction_vector(boneB,boneA)
	boneB.add_child(joint2)
	
	boneA.RelatedJoints.append(joint1)
	boneA.RelatedJoints.append(joint2)
	boneB.RelatedJoints.append(joint1)
	boneB.RelatedJoints.append(joint2)
	
	var jointLine:Line2D = Line2D.new()
	jointLine.name = "jointline"
	jointLine.add_point(boneA.global_position/100,0)
	jointLine.add_point(boneB.global_position/100,1)
	jointLine.default_color = Color(255,255,255)
	jointLine.width = 3
	jointLine.z_index = +2
	boneA.add_child(jointLine)
	LogManager.log_event(Global.Step,"[attach_bodies] jointLine In",boneA.BoneOf,boneA.name,"","")
#--------------------------------------
func break_joint(bone:Bone, jointLine:Line2D=null) -> void:
	var otherBone = bone.JoinedTo
	for joint in bone.RelatedJoints:
		if is_instance_valid(joint): joint.free()
	if jointLine: jointLine.free()
	else:
		var jointLine2:Line2D = get_node_or_null(str(str(bone.JoinedTo.get_path())+"/jointline"))
		if is_instance_valid(jointLine2): jointLine2.free()

	reset_variables(bone)
	reset_variables(otherBone)
	# call_deferred("reset_variables",bone)
	# call_deferred("reset_variables",bone.JoinedTo)
#--------------------------------------
func reset_variables(bone:Bone) -> void:
	bone.Joined = false
	bone.JoinedTo = null
	bone.RelatedJoints = []
#--------------------------------------
func add_joints_to_create_queue(boneA:Bone,boneB:Bone):
	boneA.Joined = true
	boneB.Joined = true
	JointsToCreate.append([boneA,boneB])
#--------------------------------------
func add_joints_to_break_queue(botA:Robot,botB:Robot,boneA:Bone,JointLine=null):
	JointsToBreak.append([botA,botB,boneA,JointLine])
#--------------------------------------
func resolve_joints_to_create_queue():
	if JointsToCreate:
		for joint in JointsToCreate:
			print
			if not(joint[0].get_parent().get_parent().MarkedForDeath) and not(joint[1].get_parent().get_parent().MarkedForDeath):
				attach_bodies(joint[0],joint[1])
				EnergyBankManager.joint_made(joint[0],joint[1])
				LogManager.log_event(Global.Step,"[resolve_union] attachment",joint[0].BoneOf,joint[0].name,joint[1].BoneOf,joint[1].name)
			JointsToCreate.clear()
#--------------------------------------
func resolve_joints_to_break_queue():

	if JointsToBreak:
		for joint in JointsToBreak:
			if not(joint[0].MarkedForDeath) and not (joint[1].MarkedForDeath):
				LogManager.log_event(Global.Step,"[resolve_break] de-attachment",joint[0].RobotID, joint[2].name,joint[1].RobotID ,"")
				if is_instance_valid(joint[3]):
					break_joint(joint[2],joint[3])	
					EnergyBankManager.joint_broke(joint[0],joint[1])
			JointsToBreak.clear()
#--------------------------------------
func resolve_deaths():
	pass
#--------------------------------------
func death(bot:Robot) -> void: 
	Global.QtyRobotsAlive -= 1
	for bone in bot.Bones:
		if (bone.Joined) and (is_instance_valid(bone.JoinedTo)):
			var jointLine:Line2D = bone.JoinedTo.get_node_or_null("jointline")
			if jointLine: jointLine.free()
		for joint in bone.RelatedJoints:
			if is_instance_valid(joint):
				joint.free()
	bot.free()
	Global.BotsAtEnergyBank[bot.EnergyBankIndex].erase(bot)
	if (bot.EnergyBankIndex>0):
		if bot.RobotID in Global.EnergyBankConnections[bot.EnergyBankIndex]:
			for connectedBot in Global.EnergyBankConnections[bot.EnergyBankIndex][bot.RobotID]:
				Global.EnergyBankConnections[bot.EnergyBankIndex][connectedBot].erase(bot.RobotID)	
			Global.EnergyBankConnections[bot.EnergyBankIndex].erase(bot.RobotID)
		if (Global.BotsAtEnergyBank[bot.EnergyBankIndex].size() < 1):
			EnergyBankManager.remove_energy_bank.call_deferred(bot.EnergyBankIndex)
#--------------------------------------