extends Node
var address:String = "/home/nonato/GodotProjects/Projects/LogsFromSoftbodyGodot/"#"res://Logs/"

var EventLog:Array = []
var FrameLog:Array = []
var GeneralLog:Array = []
var EnergyBankOpsLog:Array = []

func log_event(step:int, eventType:String, botA:String, boneA:String, botB:String, boneB:String):
	EventLog.append([step, 
					eventType,
					botA,boneA,
					botB,boneB])

func log_frame_data(step:int, message:String, bot:Robot):
	FrameLog.append([step, 
					bot.name,
					bot.Age,
					bot.BornIn,
					message, 
					bot.EnergyBankIndex,
					bot.MovementDirection,
					bot.Bones[bot.CenterBoneIndex].linear_velocity,
					get_robots_joints(bot),
					])
			
func log_general(step:int,message:String,energyBank:Dictionary, botsAtEnergyBank:Dictionary, energyBankConnections:Dictionary):
	GeneralLog.append([step,
						message,
						energyBank.duplicate(true),
						snapshot_bots_at_energybank(botsAtEnergyBank),
						energyBankConnections.duplicate(true)                         
						])

func log_energyBank_ops(step:int,message:String,botA:String, botABank:int, botB:String="", botBBank:int=999999, targetBank:int=999999):
	EnergyBankOpsLog.append([step,
							message,
							botA, botABank, 
							botB, botBBank,
							targetBank])

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
	# print(FrameLog)
	var eventFile = FileAccess.open(address+"/EventLog.csv",FileAccess.WRITE)
	eventFile.store_line("step, eventType, botA.name, boneA, botB.name, boneB")
	var frameFile = FileAccess.open(address+"/FrameLog.csv",FileAccess.WRITE)
	frameFile.store_line("step, bot.name, bot.movementDirection, bot.linearVelocity, bot.joints")
	var generalFile = FileAccess.open(address+"/GeneralLog.csv",FileAccess.WRITE)
	generalFile.store_line("step, message, EnergyBank, BotsAtEnergyBank, EnergyBankConnections")
	var energyBankFile = FileAccess.open(address+"/EnergyBankOps.csv",FileAccess.WRITE)
	energyBankFile.store_line("step, message, botA.name, botA.EnergyBank, botB.name, botB.EnergyBank (999999=place holder), targetBank (999999=place holder)")

	for line in EventLog:
		eventFile.store_line(get_string_from_array(line))
	
	for line in FrameLog:
		frameFile.store_line(get_string_from_array(line))

	for line in GeneralLog:
		generalFile.store_line(get_string_from_array(line))

	for line in EnergyBankOpsLog:
		energyBankFile.store_line(get_string_from_array(line))

	eventFile.close()
	frameFile.close()
	generalFile.close()
	energyBankFile.close()

func print_state():
	pass
	# var output:String = "=========STATE=========\n"
	# output += str(Global.BotsAtEnergyBank)
	# for bank in Global.BotsAtEnergyBank:
	# 	output += "\n-----"+str(bank)+": "+str(Global.BotsAtEnergyBank[bank].size())+" -> "+str(Global.EnergyBankConnections[bank])
	# output += "\n======================="
	# return output

	# print("=========STATE=========")
	# print(Global.BotsAtEnergyBank)
	# for bank in Global.BotsAtEnergyBank:
	#     print("-----"+str(bank)+": "+str(Global.BotsAtEnergyBank[bank].size())+" -> "+str(Global.EnergyBankConnections[bank]))
	# print("=======================")

func get_robots_joints(bot:Robot) -> String:
	var output:String = ""
	for bone in bot.Bones:
		if bone.Joined and is_instance_valid(bone.JoinedTo):
			output += str(bone.JoinedTo.BoneOf)+","
	return output

func snapshot_bots_at_energybank(botsAtEnergyBank:Dictionary) -> Dictionary:
	var snapshot:Dictionary = {}
	for energyBank in botsAtEnergyBank.keys():
		snapshot[energyBank] = []
		for bot in botsAtEnergyBank[energyBank]:
			snapshot[energyBank].append(str(bot.name))
	return snapshot
