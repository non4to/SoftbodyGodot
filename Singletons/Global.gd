extends Node
const ROBOT = preload("res://Scenes/Robot/robot.tscn")

var Seed
var RandomSeed:bool = true
var MaxStep:int = 100000
var FPS:int = 20
var MutationRate:float = 0.001
var LogAddress:String = "/home/non4to/Documentos/SoftBodyLogs"
var WorldSize:Vector2 = Vector2(1000,1000)
var StartPopulation:int = 25

#FoodSpawnerConst
var FSEnergyArea: float = 500
var FSMaxEnergyStorage: float = 500
var FSStandardGivenEnergy:float = 1
var FSRechargeRate:float = FSStandardGivenEnergy*1.25
var FSInfiniteFood:bool = true

#RobotConst
var BOTCenterBoneIndex:int = 4
var BOTMaxEnergyPossible: int = 250  						#Maximum Energy possible
var BOTMovingEnergyMult: float = 0.010 					#Multiply this by the Force of the movement to obtain the Energy Cost
var BOTMetabolism: float = FSStandardGivenEnergy*0.5				#Metabolism. Every step this value is deduced from Energy
var BOTMaxForcePossible: float = 30*1.5  						#Maximum Movement Force possible
var BOTJoinThresold: float = BOTMaxForcePossible*2.5		#if a collision happens while above this, they joint
var BOTUsingJoinThresold: bool = false
var BOTChangeDirectionDelay: float = 0					#How many steps before being allowed to change direction
var BOTReplicationCoolDown:int = 250
var BOTCriticalAge:int = 5000
var BOTDeathOfAge:bool = false
var BOTMaxDeathProb:float = 0.8
var BOTBonesThatCanJoin:Array = [1,3,5,7]

#####################################################################
##################################################################
var EnergyBank: Dictionary = {0: 0} 				# All existing energybanks -> Robots with the same index share the energy contained in the bank
var BotsAtEnergyBank: Dictionary = {0: []}				# Saves the bots qty occupy EnergyBank
var EnergyBankConnections: Dictionary = {0: []}
var QtyEnergyBanksCreated: int = 0
var QtyRobotsCreated: int = 0 
var QtyRobotsCreatedBySpawner: int = 0
var QtyRobotsAlive: int = 0
###
var Step:int = 0
var SaveFrames:bool = true
var SavedFrames:int = 0
var PendingFrames:Array = []
var RobotSpawners = []
var Duration
###
var OldestAge:int = 0
var StopStep:int = 0

func _init() -> void:
	load_parameters_from_file("res://Parameters.json")

	if RandomSeed:
		var now = Time.get_unix_time_from_system()
		Seed = int(now) % 1000000000
	seed(Seed)
	initialize_log_adress()

func _process(_delta: float) -> void:
	Duration = ((Time.get_ticks_msec())/1000)
	if PendingFrames:
		SavedFrames += 1
		save_frame()
#---------------------------------------
func _physics_process(_delta: float) -> void:
	#-------------------------------------
	EventManager.resolve_events()
	#-------------------------------------
	Assertation.assert_dicts_size()
	#-------------------------------------
	for bank in BotsAtEnergyBank:
		for bot in BotsAtEnergyBank[bank]:
			if is_instance_valid(bot):
				LogManager.log_bot_snapshot(bot)
	LogManager.log_general("general",Global.EnergyBank,Global.BotsAtEnergyBank,Global.EnergyBankConnections)
	#-------------------------------------
	if (SaveFrames) and (Step%FPS==0):
		add_frame_to_queue()
		LogManager.save_log()
	#-------------------------------------
	if (QtyRobotsAlive == 0)and(Step>15):
		LogManager.end_sim(0,"")
		get_tree().quit()
	if Global.Step > Global.MaxStep:
		LogManager.end_sim(1,"")
		get_tree().quit()
	#-------------------------------------
	Step += 1
	#-------------------------------------

#==============================================================================
#==============================================================================
#==============================================================================
func wrap_position(body: Node2D):
	if body.global_position.x < 0:
		body.global_position.x += WorldSize.x
	elif body.global_position.x > WorldSize.x:
		body.global_position.x -= WorldSize.x
	
	if body.global_position.y < 0:
		body.global_position.y += WorldSize.y
	elif body.global_position.y > WorldSize.y:
		body.global_position.y -= WorldSize.y
#---------------------------------------
func normalize_probs(itemsDict:Dictionary) -> Dictionary:
	var total:float = 0
	for value in itemsDict.values():
		total += value

	if total==0.0:
		assert(false,"cant normalize")
	var normalizedDict:Dictionary = {}
	for item in itemsDict.keys():
		normalizedDict[item] = itemsDict[item]/total
	return normalizedDict
#---------------------------------------
func weighted_choice(itemsDict:Dictionary) -> String:
	itemsDict = normalize_probs(itemsDict)
	var rand:float = randf()
	var cumulative:float = 0
	for item in itemsDict:
		cumulative += itemsDict[item]
		if rand <= cumulative:
			return item
	return itemsDict.keys()[-1]
#--------------------------------------
func mutate_gene(gene:Array) -> Array:
	var partToMutate: int = randi_range(0,gene.size()-1)
	var mutated_gene: Array = gene.duplicate(true)
	if (partToMutate>=0)and(partToMutate<=2):
		var keys = mutated_gene[partToMutate].keys()
		var randKey = keys[randi_range(0,keys.size()-1)]
		var randValue = randi_range(-1,1)
		while randValue==0:
			randValue = randi_range(-1,1)
		mutated_gene[partToMutate][randKey] += 0.25*randValue
		mutated_gene[partToMutate] = normalize_probs(mutated_gene[partToMutate])
	else:
		var mutation:int = randi_range(-1,1)
		while mutation==0:
			mutation = randi_range(-1,1)
		mutated_gene[partToMutate] +=  mutation

		if mutated_gene[partToMutate] > 4:
			mutated_gene[partToMutate] = mutated_gene[partToMutate]%4
		if mutated_gene[partToMutate] < 0:
			mutated_gene[partToMutate] = 4 + mutated_gene[partToMutate]

	return mutated_gene
#--------------------------------------
func get_direction_vector(fromA:Node,toB:Node) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector
#--------------------------------------
func is_unit_vector(vector:Vector2):
	return abs(vector.length_squared() - 1) < 0.001
#--------------------------------------
func save_frame():
	var frameData = PendingFrames.pop_front()
	var img = frameData["img"]
	# var step = frameData["step"]
	var path = LogAddress+"/frames/frame_%06d.png" % SavedFrames
	img.save_png(path)
#--------------------------------------
func add_frame_to_queue() -> void:
	await RenderingServer.frame_post_draw  
	var img = get_viewport().get_texture().get_image()
	PendingFrames.append({"step":Step, "img":img})
#--------------------------------------
func deferred_assert() -> void:
	Assertation.resolve_assert()
#--------------------------------------
func initialize_log_adress() -> void:
	var time = Time.get_datetime_string_from_system(true,true)
	time = time.replace(":", "-").replace(" ", "_")
	var main_dir = time+"_s"+str(MaxStep)
	var dir = DirAccess.open(LogAddress)
	if dir:
		if not dir.dir_exists(main_dir):
			dir.make_dir(main_dir)
			

	LogAddress += "/"+main_dir
	dir = DirAccess.open(LogAddress)
	dir.make_dir("frames")
#--------------------------------------
func progress_bar(current: int, total: int) -> void:
	var percent := float(current) / total
	var bar_width := 40
	var filled := int(percent * bar_width)
	var bar := "[" + "#".repeat(filled) + "-".repeat(bar_width - filled) + "]"
	var display := "%s %3d%% (%d/%d steps)" % [bar, int(percent * 100), current, total]
	
	# \r volta ao início da linha, OS.flush_stdout() força o print
	print(display)
#--------------------------------------
func initialize_random_gene() -> Array:
	var movementProbs:Dictionary = {"N":0.1,"S":0.1,"E":0.1,"W":0.1,"Z":0.6} #Green direction, Blue direction, Red direction, Yellow direction, (Zero movement)
	var attachProbability:Dictionary = {0:1, 1:0.8, 2:0.4, 3:0.6} # Qty of links robot has
	var dettachProbability:Dictionary = {1:0.0001, 2:0.0001, 3:0.005, 4:0.5}# Qty of links robot has
	var deathLimit:int = 3 #If this number of links or more, die.
	var limitToReplicate:int = 0

	for key in movementProbs.keys():
		movementProbs[key] = randf()
	movementProbs = Global.normalize_probs(movementProbs)

	for key in attachProbability.keys():
		attachProbability[key] = randf_range(0,1)

	for key in dettachProbability.keys():
		dettachProbability[key] = randf_range(0,1)

	deathLimit = randi_range(1,4)
	limitToReplicate = randi_range(0,4)
	var gene = [movementProbs,attachProbability,dettachProbability,deathLimit,limitToReplicate]
	return gene
#--------------------------------------
func load_parameters_from_file(paramsFile:String) -> void:
	var file = FileAccess.open(paramsFile, FileAccess.READ)
	if file == null:
		assert(false,"Failed to open Parameters file")
	
	var content = file.get_as_text()
	var result = JSON.parse_string(content)
	if typeof(result) != TYPE_DICTIONARY:
		assert(false,"Failed to parse JSON correctly.")

	BOTBonesThatCanJoin = result["Bots"].get("BonesThatCanJoin", BOTBonesThatCanJoin)
	BOTCenterBoneIndex = result["Bots"].get("CenterBoneIndex", BOTCenterBoneIndex) 
	BOTMaxEnergyPossible = result["Bots"].get("MaxEnergyPossible", BOTMaxEnergyPossible) 	
	BOTMovingEnergyMult = result["Bots"].get("MovingEnergyMult", BOTMovingEnergyMult) 
	BOTMetabolism = result["Bots"].get("Metabolism", BOTMetabolism) 	
	BOTMaxForcePossible = result["Bots"].get("MaxForcePossible", BOTMaxForcePossible) 
	BOTJoinThresold = result["Bots"].get("JoinThresold", BOTJoinThresold)  
	BOTUsingJoinThresold = result["Bots"].get("UsingJoinThresold", BOTUsingJoinThresold) 
	BOTChangeDirectionDelay = result["Bots"].get("ChangeDirectionDelay", BOTChangeDirectionDelay) 
	BOTReplicationCoolDown = result["Bots"].get("ReplicationCoolDown", BOTReplicationCoolDown)  
	BOTCriticalAge = result["Bots"].get("CriticalAge", BOTCriticalAge) 
	BOTDeathOfAge = result["Bots"].get("DeathOfAge", BOTDeathOfAge) 
	BOTMaxDeathProb = result["Bots"].get("MaxDeathProb", BOTMaxDeathProb) 

	FSEnergyArea = result["FoodSource"].get("EnergyArea", FSEnergyArea)
	FSMaxEnergyStorage = result["FoodSource"].get("MaxEnergyStorage", FSMaxEnergyStorage)
	FSStandardGivenEnergy = result["FoodSource"].get("StandardGivenEnergy", FSStandardGivenEnergy)
	FSRechargeRate = result["FoodSource"].get("RechargeRate", FSRechargeRate)
	FSInfiniteFood = result["FoodSource"].get("InfiniteFood", FSInfiniteFood)

	StartPopulation = result["General"].get("StartPopulation", StartPopulation)
	Seed = result["General"].get("Seed", Seed) 
	RandomSeed =  result["General"].get("RandonSeed", RandomSeed) 
	MaxStep = result["General"].get("MaxStep", MaxStep)
	FPS = result["General"].get("FPS", FPS)
	MutationRate = result["General"].get("MutationRate", MutationRate)
	LogAddress = result["General"].get("LogAddress", LogAddress)
	var worldSizeArray = result["General"].get("WorldSize", WorldSize)
	WorldSize = Vector2(worldSizeArray[0],worldSizeArray[1])
