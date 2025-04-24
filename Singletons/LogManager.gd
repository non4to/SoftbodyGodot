extends Node
var address:String = "/home/nonato/GodotProjects/Projects/LogsFromSoftbodyGodot/"#"res://Logs/"

var DEBUGEventLog:Array = []
var EventLog:Array = []
var BotStepLog:Array = []
var GeneralLog:Array = []
var EnergyBankOpsLog:Array = []

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
	# print(BotStepLog)
	var eventFile = FileAccess.open(address+"/EventLog.csv",FileAccess.WRITE)
	eventFile.store_line("[BREAK],Global.Step,botA.RobotID,botB.RobotID,message")
	var debugEventFile = FileAccess.open(address+"/DEBUGEventLog.csv",FileAccess.WRITE)
	debugEventFile.store_line("step, eventType, botA.name, boneA, botB.name, boneB")
	var frameFile = FileAccess.open(address+"/BotStepLog.csv",FileAccess.WRITE)
	frameFile.store_line("step, bot.name, bot.movementDirection, bot.linearVelocity, bot.joints")
	var generalFile = FileAccess.open(address+"/GeneralLog.csv",FileAccess.WRITE)
	generalFile.store_line("step, message, EnergyBank, BotsAtEnergyBank, EnergyBankConnections")
	
	for line in EventLog:
		eventFile.store_line(get_string_from_array(line))

	for line in DEBUGEventLog:
		debugEventFile.store_line(get_string_from_array(line))
	
	for line in BotStepLog:
		frameFile.store_line(get_string_from_array(line))

	for line in GeneralLog:
		generalFile.store_line(get_string_from_array(line))

	eventFile.close()
	debugEventFile.close()
	frameFile.close()
	generalFile.close()

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
	var output:Array = []
	output.append([Global.Step, 
				bot.RobotID,
				bot.Age,
				bot.BornIn,
				bot.EnergyBankIndex,
				bot.MovementDirection,
				bot.Bones[bot.CenterBoneIndex].linear_velocity,
				Assertation.get_robots_joints(bot),
				])
	return output
