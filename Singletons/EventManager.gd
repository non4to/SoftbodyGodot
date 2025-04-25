extends Node
const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.tscn")

var JointsToBreak:Array = []
var JointsToCreate:Array = []
var BotsToDie:Array = []
var BanksToErase:Array = []

#--------------------------------------
func resolve_events():
	pass
	resolve_deaths()
	# resolve_joints_to_create_queue()
	# resolve_joints_to_break_queue()
	resolve_erase_banks()
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
	boneA.Joined = true
	boneB.Joined = true
	
	var jointLine:Line2D = Line2D.new()
	jointLine.name = "jointline"
	jointLine.add_point(boneA.global_position/100,0)
	jointLine.add_point(boneB.global_position/100,1)
	jointLine.default_color = Color(255,255,255)
	jointLine.width = 3
	jointLine.z_index = +2
	boneA.add_child(jointLine)

	LogManager.log_event("[attach_bodies] jointLine In" +str(boneA.BoneOf)+","+str(boneA.name))
#--------------------------------------
func break_joint(bone:Bone, jointLine=null) -> void:
	var otherBone = bone.JoinedTo
	for joint in bone.RelatedJoints:
		if is_instance_valid(joint): joint.free()
	for joint in otherBone.RelatedJoints:
		if is_instance_valid(joint): joint.free()
	
	if jointLine: jointLine.free()
	else:
		var jointLine2:Line2D = get_node_or_null(str(str(bone.JoinedTo.get_path())+"/jointline"))
		if is_instance_valid(jointLine2): jointLine2.free()

	reset_variables(bone)
	reset_variables(otherBone)
	LogManager.log_event("-----[break_joint] Physical Joint broken ({0} x {1})".format([bone.name, otherBone.name]))
#--------------------------------------
func reset_variables(bone:Bone) -> void:
	bone.Joined = false
	bone.JoinedTo = null
	bone.RelatedJoints.clear()
#--------------------------------------
func add_joints_to_create_queue(boneA:Bone,boneB:Bone):
	JointsToCreate.append([boneA,boneB])
#--------------------------------------
func add_joints_to_break_queue(botA:Robot,botB:Robot,boneA:Bone,jointLine=null):
	JointsToBreak.append([botA,botB,boneA,jointLine])
#--------------------------------------
func add_bot_to_die(bot:Robot):
	bot.MarkedForDeath = true
	BotsToDie.append(bot)
#--------------------------------------
func add_bank_to_erase(bank:int):
	BanksToErase.append(bank)
#--------------------------------------
func resolve_create_joint(boneA:Bone, boneB:Bone):
	LogManager.log_event("[resolving unions...]")
	var botA = boneA.get_parent().get_parent()
	var botB = boneB.get_parent().get_parent()
	if is_instance_valid(botA) and is_instance_valid(botB) and not(boneA.Joined) and not(boneB.Joined):
		attach_bodies(boneA,boneB)
		EnergyBankManager.joint_made(boneA,boneB)
		LogManager.log_event("[resolved_union] Attachment "+str(boneA.BoneOf)+","+str(boneA.name)+" x "+str(boneB.BoneOf)+","+str(boneB.name))
	Assertation.assert_bot_connections(botA)
	Assertation.assert_bot_connections(botB)
#--------------------------------------
func resolve_break_joint(botA:Robot, botB:Robot, boneA:Bone, jointLine):
	if is_instance_valid(botA) and is_instance_valid(botB) and (boneA.Joined):
		LogManager.log_event("[resolving breaks...]")
		break_joint(boneA,jointLine)	
		EnergyBankManager.joint_broke(botA,botB)
		LogManager.log_event("[resolved_break] De-attachment "+str(botA.RobotID)+","+str(boneA.name)+"x"+str(botB.RobotID)+" -j.line "+str(jointLine))
	Assertation.assert_bot_connections(botA)
	Assertation.assert_bot_connections(botB)
#--------------------------------------
func resolve_erase_banks():
	if BanksToErase:
		for bank in BanksToErase:
			remove_bank(bank)
		BanksToErase.clear()
#--------------------------------------
func resolve_deaths() -> void:
	if BotsToDie:
		for bot in BotsToDie:
			if is_instance_valid(bot):
				LogManager.log_event("[resolve_death] death "+str(bot.RobotID))
				death(bot)
		BotsToDie.clear()
#--------------------------------------
func death(bot:Robot) -> void: 
	Global.QtyRobotsAlive -= 1
	if (bot.EnergyBankIndex>0):
		if not(bot.EnergyBankIndex in Global.EnergyBankConnections):
			LogManager.save_log()
			assert(false,"Error. Trying to access a energy bank connection that does not exist.")

		#All this is probably not necessary, as the most necessary thing would be just to update the CONNECTIONS 
		for bone in bot.Bones:
			if is_instance_valid(bone.JoinedTo):
				var otherBot = bone.JoinedTo.get_parent().get_parent()
				var jointLine = get_node_or_null(str(str(bone.get_path())+"/jointline"))
				if (bone.Joined) and (is_instance_valid(bone.JoinedTo)):
					resolve_break_joint(bot,otherBot,bone,jointLine)
	Global.BotsAtEnergyBank[bot.EnergyBankIndex].erase(bot)
	bot.free()
#--------------------------------------
func remove_bank(bank:int) ->void:
	if (Global.BotsAtEnergyBank[bank].size()>0):
		LogManager.save_log()
		assert(false,"Bank ["+str(bank)+"] cannot be erased if there are bots in it")

	Global.EnergyBank.erase(bank)
	Global.BotsAtEnergyBank.erase(bank)
	Global.EnergyBankConnections.erase(bank)
	pass
#--------------------------------------
