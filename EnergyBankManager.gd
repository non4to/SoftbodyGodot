extends Node

const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.gd")

func remove_energy_bank(index:int) ->void:
	Global.EnergyBank.erase(index)
	Global.BotsAtEnergyBank.erase(index)
	Global.EnergyBankConnections.erase(index)

func connect_signals(robot:Robot) -> void:
	robot.connect("joint_broke", _on_joint_break)
	robot.connect("joint_made", _on_joint_made)

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

func assign_energy_bank(botA: Robot, botB:Robot) -> void:
	if (botA.EnergyBankIndex > 0): 
		if (botB.EnergyBankIndex > 0): 
			#A(in)B(in)
			var bot:Robot
			if botA.EnergyBankIndex < botB.EnergyBankIndex:
				for i in range(Global.BotsAtEnergyBank[botB.EnergyBankIndex].size()):
					bot = Global.BotsAtEnergyBank[botB.EnergyBankIndex][0]
					move_to_energy_bank(bot, botA.EnergyBankIndex)
				merge_energy_bank_conections(botB.EnergyBankIndex,botA.EnergyBankIndex)
				# connect_energy_bank_conections(botB,botA)


			elif botA.EnergyBankIndex > botB.EnergyBankIndex:
				for i in range(Global.BotsAtEnergyBank[botA.EnergyBankIndex].size()):
					bot = Global.BotsAtEnergyBank[botB.EnergyBankIndex][0]
					move_to_energy_bank(bot, botB.EnergyBankIndex)
				merge_energy_bank_conections(botA.EnergyBankIndex,botB.EnergyBankIndex)
				# connect_energy_bank_conections(botB,botA)
		else: 
			#A(in)B(out)
			move_to_energy_bank(botB,(botA.EnergyBankIndex))
			connect_energy_bank_conections(botB,botA)
	else: 
		if (botB.EnergyBankIndex > 0):
			#A(out)B(in)
			move_to_energy_bank(botA,(botB.EnergyBankIndex))
			connect_energy_bank_conections(botA,botB)
		else: 
			#A(out)B(out)
			Global.QtyEnergyBanksCreated  += 1
			var newBank:int = Global.QtyEnergyBanksCreated 

			Global.EnergyBank[newBank] = 0
			Global.BotsAtEnergyBank[newBank] = []

			move_to_energy_bank(botA,newBank)
			move_to_energy_bank(botB,newBank)	
			connect_energy_bank_conections(botA,botB)

func merge_energy_bank_conections(oldBank:int, mergedBank:int):
	if not (oldBank in Global.EnergyBankConnections) or not (mergedBank in Global.EnergyBankConnections):
		assert(false,"Both banks need to exist already to be merged")

	print(Global.EnergyBankConnections[oldBank])
	print(Global.EnergyBankConnections[mergedBank])
	print()
	
	for robotKey in Global.EnergyBankConnections[oldBank]:
		# print(robotKey,Global.EnergyBankConnections[mergedBank])
		if not(robotKey in Global.EnergyBankConnections[mergedBank]):
			Global.EnergyBankConnections[mergedBank][robotKey] = []
		
		for eachConnection in Global.EnergyBankConnections[oldBank][robotKey]:
			Global.EnergyBankConnections[mergedBank][robotKey].append(eachConnection)
			# print(Global.EnergyBankConnections[mergedBank][robotKey])

			assert(false,"derp")

func connect_energy_bank_conections(botA:Robot, botB:Robot):
	#Creates a conections between botA and botB
	if not(botA.EnergyBankIndex==botB.EnergyBankIndex):
		print(botA.name,botB.name)
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

	if not (botA.RobotID in Global.EnergyBankConnections[currentBank][botB.RobotID]):
		Global.EnergyBankConnections[currentBank][botB.RobotID].append(botA.RobotID)

	if not (botB.RobotID in Global.EnergyBankConnections[currentBank][botA.RobotID]):
		Global.EnergyBankConnections[currentBank][botA.RobotID].append(botB.RobotID)

func _on_joint_break(botA:Robot,botB:Robot):
	if botA.EnergyBankIndex == 0: 
		assert(false,"Robot has EnergyBankIndex=0 but just had a joint broken")
	if botA.is_alone():
		move_to_energy_bank(botA,0)
	if botB.is_alone():
		move_to_energy_bank(botB,0)

func _on_joint_made(boneA:Bone, boneB:Bone):
	var botA:Robot = boneA.get_parent().get_parent()
	var botB:Robot = boneB.get_parent().get_parent()
	assign_energy_bank(botA,botB)

