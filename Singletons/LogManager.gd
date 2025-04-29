extends Node
var address:String = "/home/non4to/Documentos/SoftBodyLogs"

var DEBUGEventLog:Array = []
var EventLog:Array = []
var BotStepLog:Array = []
var GeneralLog:Array = []
var EnergyBankOpsLog:Array = []
var BotLog:Array= []

func log_bot(bot:Robot, message:String="") -> void:
	var log_line = ["["+str(bot.RobotID)+"]", message, bot.BornIn, bot.Gene]
	BotLog.append(log_line)

func log_break_event(botA:Robot, botB:Robot, message:String="") -> void:
	var log_line = ["[BREAK]", Global.Step,	botA.RobotID, botB.RobotID]
	if not (message==""): log_line.append(message)
	EventLog.append(log_line)

func log_join_event(botA:Robot, botB:Robot, message:String="") -> void:
	var log_line = ["[JOIN]", Global.Step,	botA.RobotID, botB.RobotID]
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


func save_log(): 
	var time = Time.get_datetime_string_from_system(true,true)
	var dir = DirAccess.open(address)

	if dir:
		if not dir.dir_exists(time):
			dir.make_dir(time)

	address += "/"+time
	var botFile = FileAccess.open(address+"/BotsLog.json",FileAccess.WRITE)
		# ("[Bot],bornIn,[MovementProbs, AttachProbability, DettachProbability, DeathLimit, LimitToReplicate]")
	var eventFile = FileAccess.open(address+"/EventLog.json",FileAccess.WRITE)
		# ("[EVENT],Step, botA, botB, message")
	var debugEventFile = FileAccess.open(address+"/DEBUGEventLog.json",FileAccess.WRITE)
	var botStepFile = FileAccess.open(address+"/BotStepLog.json",FileAccess.WRITE)
		# ("Step, Bot, Age, BornIn, MarkedForDeath, BankIndex, MovDir, LinearVel, JoinedBots")
	var generalFile = FileAccess.open(address+"/GeneralLog.json",FileAccess.WRITE)
		# ("step, message, EnergyBanks, BotsAtEnergyBank, EnergyBankConnections")

	store_json(botFile,BotLog)
	store_json(eventFile,EventLog)
	store_json(debugEventFile,DEBUGEventLog)
	store_json(botStepFile,BotStepLog)
	store_json(generalFile,GeneralLog)

	botFile.close()
	eventFile.close()
	debugEventFile.close()
	botStepFile.close()
	generalFile.close()

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
