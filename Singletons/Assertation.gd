extends Node

# func _physics_process(_delta: float) -> void:
# 	for energyBank in Global.BotsAtEnergyBank.keys():
# 		for bot in Global.BotsAtEnergyBank[energyBank]:
# 			assert_energy_bank_index(bot,energyBank)
# 	#         call_deferred("assert_bot_connections",bot,energyBank)
# 	pass

func resolve_assert():
	for energyBank in Global.BotsAtEnergyBank.keys():
		for bot in Global.BotsAtEnergyBank[energyBank]:
			if is_instance_valid(bot):
				assert_energy_bank_index(bot,energyBank)

func assert_energy_bank_index(bot:Robot,energyBank:int) -> void:
	if not(bot.EnergyBankIndex==energyBank):
		var errorMsg:String = "[ERROR] "+str(bot.name)+".EnergyBankIndex is not the same as which BotsAtEnergyBank the bot is ("+str(energyBank)+")." 
		LogManager.log_event(Global.Step,errorMsg)
		LogManager.save_log()
		assert(false,errorMsg)

func assert_bot_connections(bot:Robot,energyBank:int) -> void:
	var botConnection:Array = []
	var eBBotConnection:Array = []

	for bone in bot.Bones:
		if bone.Joined and is_instance_valid(bone.JoinedTo):
			botConnection.append(bone.JoinedTo.BoneOf)
	
	if bot.RobotID in Global.EnergyBankConnections[energyBank]:
		for connection in Global.EnergyBankConnections[energyBank][bot.RobotID]:
			eBBotConnection.append(connection)
	
	if not(botConnection.size()==eBBotConnection.size()):
		var errorMsg:String = "[ERROR] "+str(bot.name)+" connected joints do no match connections in energyBank." 
		LogManager.log_event(Global.Step,errorMsg)
		LogManager.save_log()
		assert(false,errorMsg)
	else:
		var countA:Dictionary = {}
		var countB:Dictionary = {}

		for item in botConnection:
			if not(item in countA): countA[item] = 0
			countA[item] += countA.get(item,0) + 1

		for item in eBBotConnection:
			if not(item in countB): countB[item] = 0
			countB[item] += countB.get(item,0) + 1

		if not(countA==countB) and Global.Step>500:
			pass

		
		# for EBConnection in Global.

func assert_dicts_size():
	if not(Global.BotsAtEnergyBank.size() == Global.EnergyBankConnections.size()):
		LogManager.save_log()
		assert(false,"BotsAtEnergyBank and Connections dict dont have the same size.")
