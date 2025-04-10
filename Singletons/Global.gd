extends Node

#FoodSpawnerConst
const FSEnergyArea: float = 50
const FSMaxEnergyStorage: float = 500
const FSStandardGivenEnergy:float = 1
const FSRechargeRate:float = FSStandardGivenEnergy*1.25

#RobotConst
const BOTCenterBoneIndex:int = 4
const BOTMaxEnergyPossible: int = 500  						#Maximum Energy possible
const BOTMovingEnergyMult: float = 0.00 					#Multiply this by the Force of the movement to obtain the Energy Cost
const BOTMetabolism: float = FSStandardGivenEnergy*0.5				#Metabolism. Every step this value is deduced from Energy
const BOTMaxForcePossible: float = 30*1.5  						#Maximum Movement Force possible
const BOTJoinThresold: float = BOTMaxForcePossible*2.5		#if a collision happens while above this, they joint
const BOTChangeDirectionDelay: float = 10					#How many steps before being allowed to change direction

###
var EnergyBank: Dictionary = {0: 0} 				# All existing energybanks -> Robots with the same index share the energy contained in the bank
var BotsAtEnergyBank: Dictionary = {0: []}				# Saves the bots qty occupy EnergyBank
var EnergyBankConnections: Dictionary = {0: []}
var QtyEnergyBanksCreated: int = 0
var QtyRobotsCreated: int = 0 
var QtyRobotsAlive: int = 0
###
var Step:int = 0
var FinalStep:int = 9999999999
var FPS:int = 1
var SaveFrames:bool = false

###
var OldestAge:int = 0

var StopStep:int = 0

func get_direction_vector(fromA:Node,toB:Node) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector
func is_unit_vector(vector:Vector2):
	return abs(vector.length_squared() - 1) < 0.001
func save_frame() -> void:
	await RenderingServer.frame_post_draw  
	var img = get_viewport().get_texture().get_image()
	img.save_png("res://frames/frame_%08d.png" % Step)
func death(bot:Robot) -> void:
	QtyRobotsAlive -= 1
	for bone in bot.Bones:
		if (bone.Joined) and (is_instance_valid(bone.JoinedTo)):
			var jointLine:Line2D = bone.JoinedTo.get_node_or_null("jointline")
			if jointLine: jointLine.queue_free()
		for joint in bone.RelatedJoints:
			if is_instance_valid(joint):
				joint.queue_free()
	bot.queue_free()
	Global.BotsAtEnergyBank[bot.EnergyBankIndex].erase(bot)
	if (bot.EnergyBankIndex>0):
		if bot.RobotID in Global.EnergyBankConnections[bot.EnergyBankIndex]:
			for connectedBot in Global.EnergyBankConnections[bot.EnergyBankIndex][bot.RobotID]:
				Global.EnergyBankConnections[bot.EnergyBankIndex][connectedBot].erase(bot.RobotID)	
			Global.EnergyBankConnections[bot.EnergyBankIndex].erase(bot.RobotID)
		if (Global.BotsAtEnergyBank[bot.EnergyBankIndex].size() < 1):
			EnergyBankManager.remove_energy_bank.call_deferred(bot.EnergyBankIndex)

func _physics_process(_delta: float) -> void:
	if Global.Step > Global.FinalStep:
		get_tree().quit()

	################
	# print("Step: "+str(Step))
	# print(BotsAtEnergyBank)
	# for bank in BotsAtEnergyBank:
	# 	print("-----"+str(bank)+": "+str(BotsAtEnergyBank[bank].size())+" -> "+str(EnergyBankConnections[bank])) #str(BotsAtEnergyBank[bank]))
	# 	# print("-----"+str(bank)+": "+str(EnergyBankConnections[bank]))


	# 	for bot in BotsAtEnergyBank[bank]:
	# 		EnergyBankManager.assert_Njoints_Nconnections(bot)
	# # print(EnergyBankConnections)
	# print("-------------------------------------")
	##################

	LogManager.log_general(Step,"general",Global.EnergyBank,Global.BotsAtEnergyBank,Global.EnergyBankConnections)
	#SaveFrame
	if (SaveFrames) and (Step%FPS==0):
		save_frame()
	##########
	Step += 1