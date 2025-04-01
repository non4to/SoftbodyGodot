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
const BOTMaxForcePossible: int = 30  						#Maximum Movement Force possible
const BOTJoinThresold: float = 0#BOTMaxForcePossible*2.5		#if a collision happens while above this, they joint
const BOTChangeDirectionDelay: float = 10					#How many steps before being allowed to change direction

###
var Robots = []										# All Robots currently in the simulation
var EnergyBank: Dictionary = {0: 0} 				# All existing energybanks -> Robots with the same index share the energy contained in the bank
var BotsAtEnergyBank: Dictionary = {0: []}				# Saves the bots qty occupy EnergyBank
var FreeBanks: Array = []

var EnergyBank2: Dictionary = {0: 0, 1: 1000, 2: 1500}
var BotsAtEnergyBank2: Dictionary = {0: 12, 1: 2, 2: 3}


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("UNUSED_PARAMETER")
func _process(delta: float) -> void: 
	pass

# func energy_bank_assign(botA: Robot, botB: Robot) -> void:
# 	if (botA.EnergyBankIndex > 0): 
# 		#A in an energybank
# 		if (botB.EnergyBankIndex > 0): 
# 		#B in an energybank
# 			pass

# 		else: 
# 		#B not in an energybank
# 			pass

# 	else: 
# 		#A not in an energybank
# 		if (botB.EnergyBankIndex > 0): 
# 		#B in an energybank
# 			pass

# 		else: 
# 		#B not in an energybank
# 			pass
# 			# Global.BotsAtEnergyBank[botA.EnergyBankIndex].erase(botA)
# 			# Global.BotsAtEnergyBank[botB.EnergyBankIndex].erase(botB)
# 			var empty_bank:int = check_empty_energy_bank()
# 			if empty_bank > 0: 
# 				pass
# 				# Global.BotsAtEnergyBank[empty_bank].append(botA)
# 				# Global.BotsAtEnergyBank[empty_bank].append(botB)
				
# 				# botA.EnergyBankIndex = empty_bank
# 				# botB.EnergyBankIndex = empty_bank

# 				# update_energy_bank_energy(botA,botA.EnergyBankIndex)
# 				# update_energy_bank_energy(botB,botB.EnergyBankIndex)

# 			else: pass
# 				# Global.BotsAtEnergyBank.append([botA,botB])
# 				# print(BotsAtEnergyBank)

# 				# botA.EnergyBankIndex = Global.BotsAtEnergyBank.size() - 1
# 				# botB.EnergyBankIndex = Global.BotsAtEnergyBank.size() - 1

# 				# update_energy_bank_energy(botA,botA.EnergyBankIndex)
# 				# update_energy_bank_energy(botB,botB.EnergyBankIndex)
			
			# print(EnergyBank[1])
# Called when the node enters the scene tree for the first time.
func _ready() -> void: pass
	# move_to_energy_bank(1,0)
	# move_to_energy_bank(1,0)


# func move_to_energy_bank(bot: Robot, joiningBank:int) -> void:
# 	print("EB_b4: ",EnergyBank)
# 	print("Qty_b4: ",BotsAtEnergyBank)

# 	###############################################################
# 	var leavingBank:int = bot.EnergyBankIndex
# 	if not (joiningBank in EnergyBank):
# 		EnergyBank[joiningBank] = 0
# 		BotsAtEnergyBank[joiningBank] = []

# 	#LeavingBankEnergyAdjust
# 	if leavingBank > 0: EnergyBank[leavingBank] -= EnergyBank[leavingBank] / BotsAtEnergyBank[leavingBank].size()
# 	BotsAtEnergyBank[leavingBank].erase(bot)
# 	#JoiningBankEnergyAdjust
# 	if joiningBank > 0: EnergyBank[joiningBank] += bot.Energy
# 	BotsAtEnergyBank[joiningBank].append(bot)
# 	#BankChecks
# 	if (leavingBank>0)and(BotsAtEnergyBank[leavingBank].size()==0):
# 		EnergyBank[leavingBank] = 0
# 		FreeBanks.append(leavingBank)
	
# ###############################################################
# 	print()
# 	print("FreeBanks: ",FreeBanks)
# 	print("EB_aft: ",EnergyBank)
# 	print("Qty_aft: ",BotsAtEnergyBank)
# 	print()

# func check_empty_energy_bank() -> int:
# 	for i in range(1,Global.BotsAtEnergyBank.size()):
# 		if Global.BotsAtEnergyBank[i].size()==0:
# 			return i
# 	return 0
# func update_energy_bank_energy(bot: Robot, energyBankIndex:int) -> void:
# 	#the bots energy is always summed to energy bank energy
# 	EnergyBank[energyBankIndex] += bot.Energy
# 	if EnergyBank[energyBankIndex] > BotsAtEnergyBank[energyBankIndex].size()*bot.MaxEnergyPossible:
# 		EnergyBank[energyBankIndex] = BotsAtEnergyBank[energyBankIndex].size()*bot.MaxEnergyPossible
