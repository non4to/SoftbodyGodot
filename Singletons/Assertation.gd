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
		LogManager.log_event(errorMsg)
		LogManager.save_log()
		assert(false,errorMsg)

func assert_bot_connections(bot:Robot) -> void:
	#Checks if bots physical connections match the dictionary of connections
	var physicalConnections:Array = get_robots_joints(bot)
	var ebConnections:Array = get_robots_connections(bot)

	if not(physicalConnections.size()==ebConnections.size()):
		LogManager.log_bot_snapshot(bot,"[connections not match] different number")
		LogManager.log_event("[connections not match] different number, "+str(bot.RobotID))
		LogManager.log_event("Physical: "+str(physicalConnections))
		LogManager.log_event("EB: "+str(ebConnections))
		LogManager.save_log()
		assert(false,"Connection mistake")

	for connection in physicalConnections:
		if not(connection in ebConnections):
			LogManager.log_bot_snapshot(bot,"[connections not match] physical not inside eb dict")
			LogManager.log_event("Physical: "+str(physicalConnections))
			LogManager.log_event("EB: "+str(ebConnections))
			LogManager.save_log()
			assert(false,"Connection mistake")


func get_robots_connections(bot:Robot) -> Array:
	if bot.RobotID in Global.EnergyBankConnections[bot.EnergyBankIndex]:
		return Global.EnergyBankConnections[bot.EnergyBankIndex][bot.RobotID]
	else: return []

func get_robots_joints(bot:Robot) -> Array:
	var output:Array = []
	for bone in bot.Bones:
		if bone.Joined and is_instance_valid(bone.JoinedTo):
			output.append(str(bone.JoinedTo.BoneOf))
	return output

func assert_dicts_size():
	if not(Global.BotsAtEnergyBank.size() == Global.EnergyBankConnections.size()):
		LogManager.save_log()
		assert(false,"BotsAtEnergyBank and Connections dict dont have the same size.")
