extends Node

const BONE = preload("res://Scenes/Robot/bone.gd")
const ROBOT = preload("res://Scenes/Robot/robot.gd")

func remove_energy_bank(index:int) ->void:
	Global.EnergyBank.erase(index)
	Global.BotsAtEnergyBank.erase(index)

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
			elif botA.EnergyBankIndex > botB.EnergyBankIndex:
				for i in range(Global.BotsAtEnergyBank[botA.EnergyBankIndex].size()):
					bot = Global.BotsAtEnergyBank[botB.EnergyBankIndex][0]
					move_to_energy_bank(bot, botB.EnergyBankIndex)
		else: 
			#A(in)B(out)
			move_to_energy_bank(botB,(botA.EnergyBankIndex))
	else: 
		if (botB.EnergyBankIndex > 0):
			#A(out)B(in)
			move_to_energy_bank(botA,(botB.EnergyBankIndex))
		else: 
			#A(out)B(out)
			Global.QtyEnergyBanksCreated  += 1
			var newBank:int = Global.QtyEnergyBanksCreated 

			Global.EnergyBank[newBank] = 0
			Global.BotsAtEnergyBank[newBank] = []

			move_to_energy_bank(botA,newBank)
			move_to_energy_bank(botB,newBank)	
func _on_joint_break(botA:Robot,botB:Robot):
	if botA.EnergyBankIndex == 0: 
		assert(false,"Robot has EnergyBankIndex=0 but just had a joint broken")
		get_tree().quit()
	if botA.is_alone():
		move_to_energy_bank(botA,0)
	if botB.is_alone():
		move_to_energy_bank(botB,0)
func _on_joint_made(boneA:Bone, boneB:Bone):
	var botA:Robot = boneA.get_parent().get_parent()
	var botB:Robot = boneB.get_parent().get_parent()
	assign_energy_bank(botA,botB)
