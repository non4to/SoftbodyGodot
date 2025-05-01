extends Node2D

#use this if food pixel and not area
#const FOOD = preload("res://Scenes/Food/food.tscn")
#@export var MaxFoodSpawn = 15
#@export var MultToRecharge = 15
#@export var MaxThrownInpulse = 50
#var FoodAvailable = MaxFoodSpawn

#use this if area and not food pixel
@export var EnergyArea = 500
@export var MaxEnergyStorage:float = Global.FSMaxEnergyStorage
@export var StandardGivenEnergy:float = Global.FSStandardGivenEnergy
@export var RechargeRate:float = Global.FSRechargeRate
@export var EnergyStorage:float = MaxEnergyStorage
var InfiniteFood:bool = Global.FSInfiniteFood

var GivenEnergy:float = StandardGivenEnergy
var Recharging:bool = true
var RobotsInRechargeArea:int = 0
var BodiesInArea = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var shape = $FoodSpawner/RechargeArea/CollisionShape2D.shape
	$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,1)

	if shape:
		var new_shape = shape.duplicate()	
		var texture_size = $FoodSpawner/RechargeArea/Sprite2D.texture.get_size()
		
		if $FoodSpawner/RechargeArea/CollisionShape2D.shape is CircleShape2D:
			new_shape.radius = EnergyArea
			$FoodSpawner/RechargeArea/CollisionShape2D.shape = new_shape
			$FoodSpawner/RechargeArea/Sprite2D.scale = Vector2(EnergyArea*2/texture_size.x, EnergyArea*2/texture_size.y)
			
		if $FoodSpawner/RechargeArea/CollisionShape2D.shape is RectangleShape2D:
			new_shape.size = Vector2(EnergyArea,EnergyArea)
			$FoodSpawner/RechargeArea/CollisionShape2D.shape = new_shape
			$FoodSpawner/RechargeArea/Sprite2D.scale = Vector2(EnergyArea/texture_size.x, EnergyArea/texture_size.y)
	adjust_transparency()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#-----------------------------------------------------
	#use this if area and not food pixel
func _process(_delta: float) -> void:
	$"%Label".text = str(EnergyStorage)
	$"%Label2".text = str(RobotsInRechargeArea)
	adjust_transparency()

func _physics_process(_delta: float) -> void:
	if (EnergyStorage < 0):
		Recharging = true
	if Recharging:
		GivenEnergy = 0
		EnergyStorage += RechargeRate
		if EnergyStorage > MaxEnergyStorage:
			Recharging = false
	else:
		GivenEnergy = StandardGivenEnergy
		if EnergyStorage < MaxEnergyStorage:
			EnergyStorage += RechargeRate*0.5

func give_energy() -> float:
	if not(InfiniteFood):
		EnergyStorage -= GivenEnergy
	return GivenEnergy

func adjust_transparency() -> void:
	if InfiniteFood:
		$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,0.15)	
	else:
		$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,EnergyStorage/MaxEnergyStorage)	
#
	#if EnergyStorage <= 0:
		#$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,0.05*max_transparency)	
	#elif  EnergyStorage < 0.2*MaxEnergyStorage:
		#$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,0.2*max_transparency)
	#elif  EnergyStorage < 0.5*MaxEnergyStorage:
		#$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,0.5*max_transparency)
	#elif  EnergyStorage < 0.75*MaxEnergyStorage:
		#$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,0.75*max_transparency)
	#else:
		#$FoodSpawner/RechargeArea/Sprite2D.modulate = Color(1,1,1,max_transparency)
#-----------------------------------------------------
#use this if food pixel and not area
#func _process(delta: float) -> void:
	#$"%Label".text = str(FoodAvailable)
	#if FoodAvailable > 0:
		#var food = FOOD.instantiate()
		#var spawnDirection = get_direction()
		#food.position = $FoodSpawner.position + spawnDirection*10
		#food.apply_central_impulse(spawnDirection*randf_range(0.1*MaxThrownInpulse,MaxThrownInpulse))
		#add_child(food)
		#FoodAvailable -= 1
	#else:
		#FoodAvailable -= RechargeRate
		#if FoodAvailable < -MaxFoodSpawn*MultToRecharge:
			#FoodAvailable = MaxFoodSpawn
			#
#func get_direction() -> Vector2:
	#var angle = randi_range(0,360)
	#var direction = Vector2(cos(deg_to_rad(angle)),sin(deg_to_rad(angle)))
	#return direction
##-----------------------------------------------------
func _on_recharge_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("charger"):
		RobotsInRechargeArea += 1

func _on_recharge_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("charger"):
		RobotsInRechargeArea -= 1
