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

func get_direction_vector(fromA:Node,toB:Node) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector
