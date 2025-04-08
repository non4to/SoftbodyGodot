extends Node
var address:String = "res://Logs/"

var EventLog:Array = []
var FrameLog:Array = []
var GeneralLog:Array = []

func log_event(step:int, eventType:String, botA:Robot, boneA:Bone, botB:Robot, boneB:Bone):
    EventLog.append([step, 
                    eventType,
                    botA.name,boneA.name,
                    botB.name,boneB.name])

func log_frame_data(step:int, bot:Robot):
    FrameLog.append([step, 
                    bot.name, 
                    bot.MovementDirection,
                    bot.Bones[bot.CenterBoneIndex].linear_velocity,
                    get_robots_joints(bot),
                    ])
            
func log_general(step:int,logType:String):
    GeneralLog.append([step,
                        logType,
                        Global.EnergyBank,
                        Global.BotsAtEnergyBank,
                        Global.EnergyBankConnections                         
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
    # print(FrameLog)
    var eventFile = FileAccess.open(address+"/EventLog.csv",FileAccess.WRITE)
    eventFile.store_line("step, eventType, botA.name, boneA, botB.name, boneB")
    var frameFile = FileAccess.open(address+"/FrameLog.csv",FileAccess.WRITE)
    frameFile.store_line("step, bot.name, bot.movementDirection, bot.linearVelocity, bot.joints")
    var generalFile = FileAccess.open(address+"/GeneralLog.csv",FileAccess.WRITE)
    generalFile.store_line("step, logType, EnergyBank, BotsAtEnergyBank, EnergyBankConnections")

    for line in EventLog:
        eventFile.store_line(get_string_from_array(line))
    
    for line in FrameLog:
        frameFile.store_line(get_string_from_array(line))

    for line in GeneralLog:
        generalFile.store_line(get_string_from_array(line))

    eventFile.close()
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

func get_robots_joints(bot:Robot) -> String:
    var output:String = ""
    for bone in bot.Bones:
        if bone.Joined and is_instance_valid(bone.JoinedTo):
            output += str(bone.JoinedTo.BoneOf)+","
    return output

