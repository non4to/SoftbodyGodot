extends Node

const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.gd")
#---------------------------------------
func remove_energy_bank(index:int) ->void:
	Global.EnergyBank.erase(index)
	Global.BotsAtEnergyBank.erase(index)
	# Global.EnergyBankConnections.erase(index)
#---------------------------------------
func move_to_energy_bank(bot:Robot, joiningBank:int) -> void:
	var leavingBank:int = bot.EnergyBankIndex
	
	if not (joiningBank in Global.EnergyBank):
		Global.EnergyBank[joiningBank] = 0
		Global.BotsAtEnergyBank[joiningBank] = []

	#LeavingBankEnergyAdjust
	var proportionalEnergy = Global.EnergyBank[leavingBank] / Global.BotsAtEnergyBank[leavingBank].size()
	if (leavingBank>0): 
		Global.EnergyBank[leavingBank] -= proportionalEnergy
		bot.Energy = proportionalEnergy
		if Global.BotsAtEnergyBank[leavingBank].size()==1:
			EventManager.add_bank_to_erase(leavingBank)
			LogManager.log_event("[move_EB] Bank added to erase {0}".format([leavingBank]))
	Global.BotsAtEnergyBank[leavingBank].erase(bot)
	
	#JoiningBankEnergyAdjust
	if (joiningBank > 0): 
		Global.EnergyBank[joiningBank] += bot.Energy
	Global.BotsAtEnergyBank[joiningBank].append(bot)

	bot.EnergyBankIndex = joiningBank
	LogManager.log_event("[move_EB] Moved {0} [{1} > {2}]".format([bot.RobotID, leavingBank, bot.EnergyBankIndex]))
#---------------------------------------
func assign_energy_bank(botA: Robot, botB:Robot) -> void:
	if (botA.EnergyBankIndex > 0): 
		if (botB.EnergyBankIndex > 0): 
			#A(in)B(in)
			# var bot:Robot
			LogManager.log_event("[EB] Ain, Bin")
			var bankToBeEmpty:int
			var targetBank: int

			if botA.EnergyBankIndex < botB.EnergyBankIndex:
				bankToBeEmpty = botB.EnergyBankIndex
				targetBank = botA.EnergyBankIndex
			elif botB.EnergyBankIndex < botA.EnergyBankIndex:
				bankToBeEmpty = botA.EnergyBankIndex
				targetBank = botB.EnergyBankIndex				

			for bot in Global.BotsAtEnergyBank[bankToBeEmpty].duplicate():
				move_to_energy_bank(bot, targetBank)
			merge_energy_bank_conections(bankToBeEmpty,targetBank)

		else: 
			#A(in)B(out)
			LogManager.log_event("[EB] Ain, Bout")
			move_to_energy_bank(botB,(botA.EnergyBankIndex))
	else: 
		if (botB.EnergyBankIndex > 0):
			#A(out)B(in)
			LogManager.log_event("[EB] Aout, Bin ")
			move_to_energy_bank(botA,(botB.EnergyBankIndex))

		else: 
			#A(out)B(out)
			# Global.QtyEnergyBanksCreated  += 1
			# var newBank:int = Global.QtyEnergyBanksCreated 
			LogManager.log_event("[EB] Aout, Bout")
			var newBank:int = new_bank()
			move_to_energy_bank(botA,newBank)
			move_to_energy_bank(botB,newBank)	
#---------------------------------------
func deassign_energy_bank(botA: Robot, botB: Robot) -> void:
	var botAlone:bool = botA.is_alone()
	# if Global.EnergyBankConnections[botA.EnergyBankIndex][botA.RobotID].size()>1:
	# 	LogManager.log_frame_data("[deassign error]",botA)
	# 	LogManager.log_frame_data("[deassign error]",botB)
	# 	LogManager.save_log()
	# 	assert(false,"If bot is alone now, it should have only one connection")

	var botBlone:bool = botB.is_alone()
	# if Global.EnergyBankConnections[botA.EnergyBankIndex][botB.RobotID].size()>1:
		# LogManager.log_frame_data("[deassign error]",botA)
		# LogManager.log_frame_data("[deassign error]",botB)
		# LogManager.save_log()
		# assert(false,"If bot is alone now, it should have only one connection")	

	LogManager.log_event("-----[DeAssignBank] botA alone: {0}".format([botAlone]))
	LogManager.log_event("-----[DeAssignBank] botB alone: {0}".format([botBlone]))


	if (botAlone) and (botBlone):
		LogManager.log_event("-----[DeAssignBank] Both alone")
		move_to_energy_bank(botA,0)
		move_to_energy_bank(botB,0)
	elif (botAlone) and not(botBlone):
		LogManager.log_event("-----[DeAssignBank] {0} alone".format([botA.RobotID]))
		move_to_energy_bank(botA,0)
	elif not(botAlone) and (botBlone):
		LogManager.log_event("-----[DeAssignBank] {0} alone".format([botB.RobotID]))
		move_to_energy_bank(botB,0)
	else:
		LogManager.log_event("-----[DeAssignBank] Neither alone")
		if not(botA.EnergyBankIndex==botB.EnergyBankIndex):
			LogManager.save_log()
			assert(false,"Bots not alone, but should still be in the same energybank Index.")
		var currentBankConnections: Dictionary = Global.EnergyBankConnections[botA.EnergyBankIndex]
		var currentBankIndex: int = botA.EnergyBankIndex
		var output = bot_bfs(currentBankConnections, botA, botB)
		var connected:bool = output[0]
		if not(connected):
			var dictA:Dictionary = output[1]
			var dictB:Dictionary = output[2]
			var newBankB:int = new_bank()

			for bot in Global.BotsAtEnergyBank[currentBankIndex].duplicate():
				if bot.RobotID in dictB:
					move_to_energy_bank(bot,newBankB)
			
			Global.EnergyBankConnections[currentBankIndex] = dictA
			Global.EnergyBankConnections[newBankB] = dictB
			
			LogManager.log_event("[EB][DeAssignBank] "+str(botB.name)+","+str(botB.EnergyBankIndex)+" | "+str(botA.name)+","+str(botA.EnergyBankIndex))

#---------------------------------------
func new_bank() -> int:
	Global.QtyEnergyBanksCreated += 1

	Global.EnergyBank[Global.QtyEnergyBanksCreated] = 0
	Global.BotsAtEnergyBank[Global.QtyEnergyBanksCreated] = []
	Global.EnergyBankConnections[Global.QtyEnergyBanksCreated] = {}
	return Global.QtyEnergyBanksCreated
#---------------------------------------
func merge_energy_bank_conections(bankToBeEmpty:int, mergedBank:int):
	if not (bankToBeEmpty in Global.EnergyBankConnections) or not (mergedBank in Global.EnergyBankConnections):
		LogManager.save_log()
		assert(false,"Both banks need to exist already to be merged")
	
	for robotKey in Global.EnergyBankConnections[bankToBeEmpty]:
		if not(robotKey in Global.EnergyBankConnections[mergedBank]):
			Global.EnergyBankConnections[mergedBank][robotKey] = []
		for eachConnection in Global.EnergyBankConnections[bankToBeEmpty][robotKey]:
			Global.EnergyBankConnections[mergedBank][robotKey].append(eachConnection)

	LogManager.log_event("[EB][merge banks] ["+str(bankToBeEmpty)+" + "+str(mergedBank)+"]")
#---------------------------------------
func connect_energy_bank_connections(botA:Robot, botB:Robot):
	#Creates a conection between botA and botB
	var currentBank:int = botA.EnergyBankIndex

	if not (botA.RobotID in Global.EnergyBankConnections[currentBank]):
		Global.EnergyBankConnections[currentBank][botA.RobotID] = []

	if not (botB.RobotID in Global.EnergyBankConnections[currentBank]):
		Global.EnergyBankConnections[currentBank][botB.RobotID] = []

	Global.EnergyBankConnections[currentBank][botB.RobotID].append(botA.RobotID)
	Global.EnergyBankConnections[currentBank][botA.RobotID].append(botB.RobotID)
	LogManager.log_event("[EB][Connect] "+str(botA.RobotID)+" to botB: "+str(botB.RobotID)+", in bank "+str(currentBank))
	LogManager.log_event("[EB][Connect] Bank "+str(currentBank)+": "+str(Global.EnergyBankConnections[currentBank]))
#---------------------------------------
func disconnect_energy_bank_conections(botA:Robot, botB:Robot):
	if not(botA.EnergyBankIndex==botB.EnergyBankIndex):
			print(LogManager.print_state())
			print(str(botA.name)+":"+str(botA.EnergyBankIndex)+", "+str(botB.name)+":"+str(botB.EnergyBankIndex))	
			LogManager.save_log()	
			assert(false,"Bots need to be in the same bank for a connection to be unmade")

	var currentBank:int = botA.EnergyBankIndex

	if not(currentBank in Global.EnergyBankConnections):
		print(LogManager.print_state())
		print(str(botA.name)+":"+str(botA.EnergyBankIndex)+", "+str(botB.name)+":"+str(botB.EnergyBankIndex))
		print(Global.EnergyBankConnections)
		print(LogManager.get_robots_joints(botA))
		print(LogManager.get_robots_joints(botB))
		LogManager.save_log()
		assert(false,"EnergyBank needs to exist in EnergyBankConnections")

	LogManager.log_event("-----[disconnect_eb] Connections of {0} in {1}".format([botA.RobotID,botA.EnergyBankIndex]))
	LogManager.log_event("-------"+str(Global.EnergyBankConnections[currentBank][botA.RobotID]))
	LogManager.log_event("-----[disconnect_eb] Connections of {0} in {1}".format([botB.RobotID,botB.EnergyBankIndex]))
	LogManager.log_event("-------"+str(Global.EnergyBankConnections[currentBank][botB.RobotID]))

	if (botB.RobotID in Global.EnergyBankConnections[currentBank])and(botA.RobotID in Global.EnergyBankConnections[currentBank][botB.RobotID]):
		#if BotB is in current bank AND botA is in botB connections
		Global.EnergyBankConnections[currentBank][botB.RobotID].erase(botA.RobotID)
		LogManager.log_event("--------[disconnect_eb] Erase "+str(botA.RobotID)+", updated: "+str(Global.EnergyBankConnections[currentBank][botB.RobotID]))
		if Global.EnergyBankConnections[currentBank][botB.RobotID].size()<1:
			LogManager.log_event("--------[disconnect_eb] Erase "+str(botA.RobotID)+" from bank.")
			Global.EnergyBankConnections[currentBank].erase(botB.RobotID)

	if (botA.RobotID in Global.EnergyBankConnections[currentBank])and(botB.RobotID in Global.EnergyBankConnections[currentBank][botA.RobotID]):
		#if BotA is in current bank AND botB is in botA connections
		Global.EnergyBankConnections[currentBank][botA.RobotID].erase(botB.RobotID)	
		LogManager.log_event("--------[disconnect_eb] Erase "+str(botB.RobotID)+", updated: "+str(Global.EnergyBankConnections[currentBank][botA.RobotID]))
		if Global.EnergyBankConnections[currentBank][botA.RobotID].size()<1:
			LogManager.log_event("--------[disconnect_eb] Erase "+str(botB.RobotID)+" from bank.")
			Global.EnergyBankConnections[currentBank].erase(botA.RobotID)


	# if Global.EnergyBankConnections[currentBank].keys().size()<1:
	# 	Global.EnergyBankConnections.erase(currentBank)
	# 	LogManager.log_event("[EB][D] Erased Bank "+str(currentBank)+" from "+str(Global.EnergyBankConnections))
#---------------------------------------
func joint_broke(botA:Robot,botB:Robot):
	if botA.EnergyBankIndex == 0: 
		print(LogManager.print_state())
		LogManager.save_log()
		assert(false,"Robot has EnergyBankIndex=0 but just had a joint broken")	
	disconnect_energy_bank_conections(botA,botB)
	deassign_energy_bank(botA,botB)
	LogManager.log_event( "[disconected] "+str(botA.RobotID)+","+str(botB.RobotID))
#---------------------------------------
func joint_made(boneA:Bone, boneB:Bone):
	var botA:Robot = boneA.get_parent().get_parent()
	var botB:Robot = boneB.get_parent().get_parent()
	assign_energy_bank(botA,botB)
	connect_energy_bank_connections(botA,botB)
	LogManager.log_event("[EB]joint_made: "+str(botA.name)+","+str(botA.EnergyBankIndex)+" x "+str(botB.name)+","+str(botB.EnergyBankIndex))
#---------------------------------------
func bot_bfs(connections:Dictionary, botA:Robot, botB:Robot) -> Array:
	var botAName = botA.RobotID
	var botBName = botB.RobotID

	var dictA:Dictionary = {}
	var qA:Array = []
	var vA:Array = []
	var currentA:String
	var aNeighbors:Array
	if botAName in connections:
		qA.append(botAName)
	else:
		LogManager.log_event("[ERROR] Give dict: "+str(connections))
		LogManager.log_general("State:",Global.EnergyBank,Global.BotsAtEnergyBank,Global.EnergyBankConnections)
		print(botAName)
		for bone in botA.Bones:
			if bone.Joined:
				print(str(bone)+", joined: "+str(bone.Joined)+", joinedTo: "+str(bone.JoinedTo.BoneOf))
		LogManager.save_log()
		assert(false,"whats happening here_?")

	var dictB:Dictionary = {}
	var qB:Array = []
	var vB:Array = []
	var currentB:String
	var bNeighbors:Array
	if botBName in connections:
		qB.append(botBName)
	else:
		LogManager.log_event("[ERROR] Give dict: "+str(connections))
		LogManager.log_general("State:",Global.EnergyBank,Global.BotsAtEnergyBank,Global.EnergyBankConnections)
		LogManager.save_log()
		print(botBName)
		for bone in botB.Bones:
			if bone.Joined:
				print(str(bone)+", joined: "+str(bone.Joined)+", joinedTo: "+str(bone.JoinedTo.Bone))
		assert(false,"whats happening here_?")


	while qA or qB:
		if qA:
			currentA = qA.pop_front()
			vA.append(currentA)
			aNeighbors = connections[currentA]
			if aNeighbors:
				for neighbor in aNeighbors:
					if (neighbor in vB) or (neighbor in qB): return [true,dictA,dictB]
					if not(neighbor in vA) and not(neighbor in qA):
						qA.append(neighbor)

		if qB:
			currentB = qB.pop_front()
			vB.append(currentB)
			bNeighbors = connections[currentB]
			if bNeighbors:
				for neighbor in bNeighbors:
					if (neighbor in vA) or (neighbor in qA): return [true,dictA,dictB]
					if not(neighbor in vB) and not(neighbor in qB):
						qB.append(neighbor)

	for bot in connections.keys():
		if bot in vA:
			dictA[bot] = connections[bot]
		else:
			dictB[bot] = connections[bot]
	
	return [false,dictA,dictB]
#---------------------------------------
func assert_Njoints_Nconnections(bot:Robot):
	var jointsNumber:int = 0
	var joinedBones:Array = []
	var joinedToBones:Array = []
	for bone in bot.Bones:
		if bone.Joined: 
			jointsNumber += 1
			joinedBones.append(bone.name)
			joinedToBones.append(bone.JoinedTo.get_parent().get_parent().name)

	if bot.EnergyBankIndex>0:
		if not(jointsNumber==Global.EnergyBankConnections[bot.EnergyBankIndex][bot.name].size()):
			print(LogManager.print_state())
			print("Joined Bones: ",joinedBones)
			print("JoinedTo Bots:",joinedToBones)
			print("Conections:    ",Global.EnergyBankConnections[bot.EnergyBankIndex][bot.name])
			LogManager.save_log()
			assert(false,str(bot.name)+" - "+str(jointsNumber)+" joints but "+str(Global.EnergyBankConnections[bot.EnergyBankIndex][bot.name].size())+" connections.")
		
		

	


	# for conection in Global.EnergyBankConnections[bot.EnergyBankIndex][bot.name]:
	# 	print(conection)
#---------------------------------------
