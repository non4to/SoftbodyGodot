extends Node

const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.gd")

func remove_energy_bank(index:int) ->void:
	Global.EnergyBank.erase(index)
	Global.BotsAtEnergyBank.erase(index)
	Global.EnergyBankConnections.erase(index)

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
		call_deferred("remove_energy_bank",leavingBank)
	LogManager.log_energyBank_ops(Global.Step,"moved bank",bot.name, leavingBank,bot.name, bot.EnergyBankIndex,joiningBank)

func assign_energy_bank(botA: Robot, botB:Robot) -> void:
	if (botA.EnergyBankIndex > 0): 
		if botA.name=="Bot3" or botB.name=="Bot3": pass

		if (botB.EnergyBankIndex > 0): 
			#A(in)B(in)
			var bot:Robot
			var bankToBeEmpty:int
			if botA.EnergyBankIndex < botB.EnergyBankIndex:
				bankToBeEmpty = botB.EnergyBankIndex
				merge_energy_bank_conections(bankToBeEmpty,botA.EnergyBankIndex)
				for i in range(Global.BotsAtEnergyBank[bankToBeEmpty].size()):
					bot = Global.BotsAtEnergyBank[bankToBeEmpty][0]
					LogManager.log_energyBank_ops(Global.Step,"A<merge banks",bot.name, bot.EnergyBankIndex,"",999999,botA.EnergyBankIndex)
					move_to_energy_bank(bot, botA.EnergyBankIndex)
				
			elif botB.EnergyBankIndex < botA.EnergyBankIndex:
				bankToBeEmpty = botA.EnergyBankIndex
				merge_energy_bank_conections(bankToBeEmpty,botB.EnergyBankIndex)
				for i in range(Global.BotsAtEnergyBank[bankToBeEmpty].size()):
					bot = Global.BotsAtEnergyBank[bankToBeEmpty][0]
					LogManager.log_energyBank_ops(Global.Step,"B<merge banks",bot.name, bot.EnergyBankIndex,"",999999,botB.EnergyBankIndex)
					move_to_energy_bank(bot, botB.EnergyBankIndex)
		else: 
			#A(in)B(out)
			LogManager.log_energyBank_ops(Global.Step,"assign bank",botB.name, botB.EnergyBankIndex,botA.name,botA.EnergyBankIndex,botA.EnergyBankIndex)
			move_to_energy_bank(botB,(botA.EnergyBankIndex))
	else: 
		if (botB.EnergyBankIndex > 0):
			#A(out)B(in)
			LogManager.log_energyBank_ops(Global.Step,"assign bank",botA.name, botA.EnergyBankIndex,botB.name, botB.EnergyBankIndex,botB.EnergyBankIndex)
			move_to_energy_bank(botA,(botB.EnergyBankIndex))
		else: 
			#A(out)B(out)
			Global.QtyEnergyBanksCreated  += 1
			var newBank:int = Global.QtyEnergyBanksCreated 

			Global.EnergyBank[newBank] = 0
			Global.BotsAtEnergyBank[newBank] = []

			LogManager.log_energyBank_ops(Global.Step,"assign banks",botA.name, botA.EnergyBankIndex,botB.name, botB.EnergyBankIndex,newBank)
			move_to_energy_bank(botA,newBank)
			move_to_energy_bank(botB,newBank)	
			# connect_energy_bank_conections(botA,botB)

func merge_energy_bank_conections(oldBank:int, mergedBank:int):
	if not (oldBank in Global.EnergyBankConnections) or not (mergedBank in Global.EnergyBankConnections):
		print(LogManager.print_state())
		LogManager.save_log()
		assert(false,"Both banks need to exist already to be merged")

	# print(Global.EnergyBankConnections[oldBank])
	# print(Global.EnergyBankConnections[mergedBank])
	# print()
	
	for robotKey in Global.EnergyBankConnections[oldBank]:
		# print(robotKey,Global.EnergyBankConnections[mergedBank])
		if not(robotKey in Global.EnergyBankConnections[mergedBank]):
			Global.EnergyBankConnections[mergedBank][robotKey] = []
		
		for eachConnection in Global.EnergyBankConnections[oldBank][robotKey]:
			Global.EnergyBankConnections[mergedBank][robotKey].append(eachConnection)
			# print(Global.EnergyBankConnections[mergedBank][robotKey])
			# assert(false,"derp")

func connect_energy_bank_conections(botA:Robot, botB:Robot):
	#Creates a conections between botA and botB
	if not(botA.EnergyBankIndex==botB.EnergyBankIndex):
		print(LogManager.print_state())
		print(str(botA.name)+":"+str(botA.EnergyBankIndex)+", "+str(botB.name)+":"+str(botB.EnergyBankIndex))	
		print(LogManager.get_robots_joints(botA))
		print(LogManager.get_robots_joints(botB))
		LogManager.save_log()
		assert(false,"Bots need to be in the same bank for a connection to be made")
	
	var currentBank:int = botA.EnergyBankIndex

	if not (currentBank in Global.EnergyBankConnections):
		Global.EnergyBankConnections[currentBank] = {}
		Global.EnergyBankConnections[currentBank][botA.RobotID] = []
		Global.EnergyBankConnections[currentBank][botB.RobotID] = []
	
	if not (botA.RobotID in Global.EnergyBankConnections[currentBank]):
		Global.EnergyBankConnections[currentBank][botA.RobotID] = []

	if not (botB.RobotID in Global.EnergyBankConnections[currentBank]):
		Global.EnergyBankConnections[currentBank][botB.RobotID] = []

	# if not (botA.RobotID in Global.EnergyBankConnections[currentBank][botB.RobotID]):
	Global.EnergyBankConnections[currentBank][botB.RobotID].append(botA.RobotID)

	# if not (botB.RobotID in Global.EnergyBankConnections[currentBank][botA.RobotID]):
	Global.EnergyBankConnections[currentBank][botA.RobotID].append(botB.RobotID)

	LogManager.log_energyBank_ops(Global.Step,"[C] botA: "+str(Global.EnergyBankConnections[currentBank][botA.RobotID])+"botB: "+str(Global.EnergyBankConnections[currentBank][botB.RobotID]),botA.name, botA.EnergyBankIndex,botB.name, botB.EnergyBankIndex,999999)

func disconnect_energy_bank_conections(botA:Robot, botB:Robot):
	# await get_tree().process_frame
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

	# if not (botB.RobotID in Global.EnergyBankConnections[currentBank]):
	# 	print(LogManager.print_state())
	# 	print(str(botA.name)+":"+str(botA.EnergyBankIndex)+", "+str(botB.name)+":"+str(botB.EnergyBankIndex))
	# 	print(Global.EnergyBankConnections[currentBank])
	# 	print(LogManager.get_robots_joints(botA))
	# 	print(LogManager.get_robots_joints(botB))
	# 	LogManager.save_log()	
	# 	assert(false,"Entry botB not found in currenBank")

	if (botB.RobotID in Global.EnergyBankConnections[currentBank])and(botA.RobotID in Global.EnergyBankConnections[currentBank][botB.RobotID]):
		LogManager.log_energyBank_ops(Global.Step,"[D] botA: "+str(Global.EnergyBankConnections[currentBank][botA.RobotID])+"botB: "+str(Global.EnergyBankConnections[currentBank][botB.RobotID]),botA.name, botA.EnergyBankIndex,botB.name, botB.EnergyBankIndex,999999)
		Global.EnergyBankConnections[currentBank][botB.RobotID].erase(botA.RobotID)
		if Global.EnergyBankConnections[currentBank][botB.RobotID].size()<1:
			Global.EnergyBankConnections[currentBank].erase(botB.RobotID)

	# if not (botA.RobotID in Global.EnergyBankConnections[currentBank]):
	# 	print(LogManager.print_state())
	# 	print(str(botA.name)+":"+str(botA.EnergyBankIndex)+", "+str(botB.name)+":"+str(botB.EnergyBankIndex))
	# 	print(Global.EnergyBankConnections[currentBank])
	# 	print(LogManager.get_robots_joints(botA))
	# 	print(LogManager.get_robots_joints(botB))
	# 	LogManager.save_log()	
	# 	assert(false,"Entry botA not found in currenBank")

	if (botA.RobotID in Global.EnergyBankConnections[currentBank])and(botB.RobotID in Global.EnergyBankConnections[currentBank][botA.RobotID]):
		Global.EnergyBankConnections[currentBank][botA.RobotID].erase(botB.RobotID)	
		if Global.EnergyBankConnections[currentBank][botA.RobotID].size()<1:
			Global.EnergyBankConnections[currentBank].erase(botA.RobotID)

func joint_broke(botA:Robot,botB:Robot):
	if botA.EnergyBankIndex == 0: 
		print(LogManager.print_state())
		LogManager.save_log()
		assert(false,"Robot has EnergyBankIndex=0 but just had a joint broken")	

	# disconnect_energy_bank_conections(botA,botB)
	call_deferred("disconnect_energy_bank_conections",botA,botB)
	LogManager.log_energyBank_ops(Global.Step,"joint_broke_aft",botA.name, botA.EnergyBankIndex,botB.name,botB.EnergyBankIndex,999999)

	if botA.is_alone():
		move_to_energy_bank(botA,0)
	if botB.is_alone():
		move_to_energy_bank(botB,0)

func joint_made(boneA:Bone, boneB:Bone):
	var botA:Robot = boneA.get_parent().get_parent()
	var botB:Robot = boneB.get_parent().get_parent()
	LogManager.log_energyBank_ops(Global.Step,"joint_made",botA.name, botA.EnergyBankIndex,botB.name,botB.EnergyBankIndex,999999)
	assign_energy_bank(botA,botB)
	connect_energy_bank_conections(botA,botB)

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
