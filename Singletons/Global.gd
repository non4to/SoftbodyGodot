extends Node
const ROBOT = preload("res://Scenes/Robot/robot.tscn")

var LogAddress:String = "/home/non4to/Documentos/SoftBodyLogs"
const WorldSize:Vector2 = Vector2(1000,1000)
#FoodSpawnerConst
const FSEnergyArea: float = 500
const FSMaxEnergyStorage: float = 500
const FSStandardGivenEnergy:float = 1
const FSRechargeRate:float = FSStandardGivenEnergy*1.25
const FSInfiniteFood:bool = true

#RobotConst
const BOTCenterBoneIndex:int = 4
const BOTMaxEnergyPossible: int = 250  						#Maximum Energy possible
const BOTMovingEnergyMult: float = 0.010 					#Multiply this by the Force of the movement to obtain the Energy Cost
const BOTMetabolism: float = FSStandardGivenEnergy*0.5				#Metabolism. Every step this value is deduced from Energy
const BOTMaxForcePossible: float = 30*1.5  						#Maximum Movement Force possible
const BOTJoinThresold: float = BOTMaxForcePossible*2.5		#if a collision happens while above this, they joint
const BOTChangeDirectionDelay: float = 0#10					#How many steps before being allowed to change direction
const BOTReplicationCoolDown:int = 1000
const BOTCriticalAge:int = 5000
const BOTDeathOfAge:bool = false
const BOTMaxDeathProb:float = 0.8
var BOTBonesThatCanJoin:Array = [1,3,5,7]

###
var EnergyBank: Dictionary = {0: 0} 				# All existing energybanks -> Robots with the same index share the energy contained in the bank
var BotsAtEnergyBank: Dictionary = {0: []}				# Saves the bots qty occupy EnergyBank
var EnergyBankConnections: Dictionary = {0: []}
var QtyEnergyBanksCreated: int = 0
var QtyRobotsCreated: int = 0 
var QtyRobotsAlive: int = 0
###
var Step:int = 0
var FinalStep:int = 1000
var FPS:int = 15
var SaveFrames:bool = true
var SavedFrames:int = 0
var PendingFrames:Array = []
var RobotSpawners = []
var MutationRate:float = 0

###
var OldestAge:int = 0

var StopStep:int = 0

func _init() -> void:
	initialize_log()

func _process(_delta: float) -> void:
	if PendingFrames:
		SavedFrames += 1
		var frameData = PendingFrames.pop_front()
		var img = frameData["img"]
		# var step = frameData["step"]
		var path = LogAddress+"/frames/frame_%06d.png" % SavedFrames
		img.save_png(path)
#---------------------------------------
func _physics_process(_delta: float) -> void:
	if Global.Step > Global.FinalStep:
		LogManager.save_log()
		get_tree().quit()
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
	#SaveFrame
	if (SaveFrames) and (Step%FPS==0):
		save_frame()
	##########
	Step += 1
	progress_bar(Step, FinalStep)

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
	# var partToMutate: int = randi_range(1,2)
	var mutated_gene: Array = gene.duplicate(true)
	if (partToMutate>=0)and(partToMutate<=2):
		var keys = mutated_gene[partToMutate].keys()
		var randKey = keys[randi_range(0,keys.size()-1)]
		var randValue = randf_range(-1,1)
		while abs(randValue)<=0.0001:
			randValue = randf_range(-1,1)
		mutated_gene[partToMutate][randKey] += randValue
		mutated_gene[partToMutate] = normalize_probs(mutated_gene[partToMutate])
	else:
		var mutation:int = randi_range(-4,4)
		while mutation==0:
			mutation = randi_range(-4,4)
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
func save_frame() -> void:
	await RenderingServer.frame_post_draw  
	var img = get_viewport().get_texture().get_image()
	PendingFrames.append({"step":Step, "img":img})
#--------------------------------------
func deferred_assert() -> void:
	Assertation.resolve_assert()
#--------------------------------------
func initialize_log() -> void:
	var time = Time.get_datetime_string_from_system(true,true)
	time = time.replace(":", "-").replace(" ", "_")
	var main_dir = time+"_s"+str(FinalStep)
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