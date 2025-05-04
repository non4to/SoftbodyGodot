extends Node

var DEBUGEventLog:Array = []
var EventLog:Array = []
var BotStepLog:Array = []
var GeneralLog:Array = []
var EnergyBankOpsLog:Array = []
var BotLog:Array= []

var BotFile
var EventFile
var DebugEventFile
var BotStepFile
var GeneralFile

func _init() -> void:
	init_log()

func log_bot(bot:Robot, message:String="") -> void:
	var log_line = [str(bot.RobotID), message, bot.BornIn, bot.Gene]
	BotLog.append(log_line)

func log_break_event(botA:Robot, botB:Robot, message:String="") -> void:
	var log_line = ["[BREAK]", Global.Step,	botA.RobotID, botB.RobotID]
	if not (message==""): log_line.append(message)
	EventLog.append(log_line)

func log_join_event(botA:Robot, botB:Robot, message:String="") -> void:
	var log_line = ["[JOIN]", Global.Step,	botA.RobotID, botB.RobotID]
	if not (message==""): log_line.append(message)
	EventLog.append(log_line)

func log_replication_event(botA:Robot, botB:Robot, message="")->void:
	var log_line = ["[REPLICATION]", Global.Step,	botA.RobotID,"parent of", botB.RobotID]
	if not (message==""): log_line.append(message)
	EventLog.append(log_line)

func log_death_event(botA:Robot, message:String="") -> void:
	var log_line = ["[DEATH]", Global.Step,	botA.RobotID]
	if not (message==""): log_line.append(message)
	EventLog.append(log_line)

func log_event(message:String):
	DEBUGEventLog.append([Global.Step, 
					message])

func log_bot_snapshot(bot:Robot, message:String=""):
	var log_line = bot_snapshot(bot)
	if not (message==""): log_line.append(message)
	BotStepLog.append(log_line)
			
func log_general(message:String,energyBank:Dictionary, botsAtEnergyBank:Dictionary, energyBankConnections:Dictionary):
	GeneralLog.append([Global.Step,
						message,
						energyBank.duplicate(true),
						snapshot_bots_at_energybank(botsAtEnergyBank),
						energyBankConnections.duplicate(true)                         
						])

func get_string_from_array(array:Array) -> String:
	var output:String = ""
	for i in range(array.size()):
		output += str(array[i])
		if i < array.size() - 1:
			output += ","
	return output

func init_log() -> void:
	save_parameters()
	BotFile = FileAccess.open(Global.LogAddress+"/BotsLog.json",FileAccess.WRITE_READ)
		# ("[Bot],bornIn,[MovementProbs, AttachProbability, DettachProbability, DeathLimit, LimitToReplicate]")
	EventFile = FileAccess.open(Global.LogAddress+"/EventLog.json",FileAccess.WRITE_READ)
		# ("[EVENT],Step, botA, botB, message")
	DebugEventFile = FileAccess.open(Global.LogAddress+"/DEBUGEventLog.json",FileAccess.WRITE_READ)
	BotStepFile = FileAccess.open(Global.LogAddress+"/BotStepLog.json",FileAccess.WRITE_READ)
		# ("Step, Bot, Age, BornIn, MarkedForDeath, BankIndex, MovDir, LinearVel, JoinedBots")
	GeneralFile = FileAccess.open(Global.LogAddress+"/GeneralLog.json",FileAccess.WRITE_READ)
		# ("step, message, EnergyBanks, BotsAtEnergyBank, EnergyBankConnections")

func save_parameters() -> void:
	var address = Global.LogAddress+"/Parameters.json"
	var PARAMETERS = {
		"Bots"= {
			"CenterBoneIndex":Global.BOTCenterBoneIndex,
			"MaxEnergyPossible":Global.BOTMaxEnergyPossible,
			"MovingEnergyMult":Global.BOTMovingEnergyMult,
			"Metabolism":Global.BOTMetabolism,
			"MaxForcePossible":Global.BOTMaxForcePossible,
			"UsingJoinThresold":Global.BOTUsingJoinThresold,
			"JoinThresold":Global.BOTJoinThresold,
			"ChangeDirectionDelay":Global.BOTChangeDirectionDelay,
			"ReplicationCoolDown":Global.BOTReplicationCoolDown,
			"CriticalAge":Global.BOTCriticalAge,
			"DeathOfAge":Global.BOTDeathOfAge,
			"MaxDeathProb":Global.BOTMaxDeathProb,
			"BonesThatCanJoin":Global.BOTBonesThatCanJoin
		},
		"FoodSource"={
			"EnergyArea":Global.FSEnergyArea,
			"MaxEnergyStorage":Global.FSMaxEnergyStorage,
			"StandardGivenEnergy":Global.FSStandardGivenEnergy,
			"RechargeRate":Global.FSRechargeRate,
			"InfiniteFood":Global.FSInfiniteFood
		},
		"General"={
			"WorldSize":Global.WorldSize,
			"MaxStep":Global.MaxStep,
			"FPS":Global.FPS,
			"SaveFrames":Global.SaveFrames,
			"MutationRate":Global.MutationRate,
			"Seed":Global.Seed,
		}
	}
	var jsonDict = JSON.stringify(PARAMETERS, "\t")
	var file = FileAccess.open(address, FileAccess.WRITE)
	if file:
		file.store_string(jsonDict)
		file.close()
	else:
		print("Erro ao salvar JSON em:", address)

func end_sim(reason:int, msg:String=""):
	"""reason = 0 -> No bots alive
	reason = 1 -> Max Steps Reached
	reason = 1234 -> Forced by user"""
	save_log()
	while Global.PendingFrames:
		Global.save_frame()

	var address = Global.LogAddress+"/EndSimulation.json"
	var endDict = {
		"Reason":"",
		"FinalStep":Global.Step,
		"Duration(s)":Global.Duration,
		"NumberOfBotsCreatedBySpawner":Global.QtyRobotsCreatedBySpawner,
		"NumberOfBotsCreatedByReplication":Global.QtyRobotsCreated-Global.QtyRobotsCreatedBySpawner,
		"Extra":msg
	}

	if reason==0:
		endDict["Reason"] = "All bots died."
	elif reason==1:
		endDict["Reason"] = "Simulation reached its maximum step."
		endDict["NumberOfBotsAlive"] = Global.QtyRobotsAlive
	elif reason==2:
		endDict["Reason"] = "Physics frame too long! Simulation might crash!"
		endDict["NumberOfBotsAlive"] = Global.QtyRobotsAlive
		endDict["LineToReplicateSize"] = EventManager.BotsToReplicate
	elif reason==1234:
		endDict["Reason"] = "Forced by user."
		endDict["NumberOfBotsAlive"] = Global.QtyRobotsAlive
	else:
		assert(false,"Reason must be 2, 1 or 0 or 1234")

	var jsonDict = JSON.stringify(endDict, "\t")
	var file = FileAccess.open(address, FileAccess.WRITE)
	if file:
		file.store_string(jsonDict)
		file.close()
	else:
		print("Erro ao salvar JSON em:", address)

func save_log(): 
	store_json(BotFile,BotLog)
	store_json(EventFile,EventLog)
	store_json(DebugEventFile,DEBUGEventLog)
	store_json(BotStepFile,BotStepLog)
	store_json(GeneralFile,GeneralLog)
	BotLog.clear()
	EventLog.clear()
	DEBUGEventLog.clear()
	BotStepLog.clear()
	GeneralLog.clear()

func close_logs():
	BotFile.close()
	EventFile.close()
	DebugEventFile.close()
	BotStepFile.close()
	GeneralFile.close()

func store_json(file:FileAccess, logToJson:Array) -> void:
	for line in logToJson:
		file.store_line(JSON.stringify(line))

func print_state():
	var output:String = "=========STATE=========\n"
	output += str(Global.BotsAtEnergyBank)
	for bank in Global.BotsAtEnergyBank:
		output += "\n-----"+str(bank)+": "+str(Global.BotsAtEnergyBank[bank].size())+" -> "+str(Global.EnergyBankConnections[bank])
	output += "\n======================="
	return output

	# print("=========STATE=========")
	# print(Global.BotsAtEnergyBank)
	# for bank in Global.BotsAtEnergyBank:
	#     print("-----"+str(bank)+": "+str(Global.BotsAtEnergyBank[bank].size())+" -> "+str(Global.EnergyBankConnections[bank]))
	# print("=======================")

func snapshot_bots_at_energybank(botsAtEnergyBank:Dictionary) -> Dictionary:
	var snapshot:Dictionary = {}
	for energyBank in botsAtEnergyBank.keys():
		snapshot[energyBank] = []
		for bot in botsAtEnergyBank[energyBank]:
			snapshot[energyBank].append(str(bot.RobotID))
	return snapshot

func bot_snapshot(bot:Robot) -> Array:
	return [Global.Step, 
				bot.RobotID,
				bot.Age,
				bot.BornIn,
				bot.MarkedForDeath,
				bot.EnergyBankIndex,
				bot.MovementDirection,
				bot.Bones[bot.CenterBoneIndex].linear_velocity,
				Assertation.get_robots_joints(bot),
				]
