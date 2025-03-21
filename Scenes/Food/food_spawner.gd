extends Node2D

#use this if food pixel and not area
const FOOD = preload("res://Scenes/Food/food.tscn")
@export var MaxFoodSpawn = 15
@export var MultToRecharge = 15
@export var MaxThrownInpulse = 50

#for both
@export var RechargeRate = 1

#use this if area and not food pixel
@export var MaxEnergyStorage:float = 1000
@export var GivenEnergy:float = 3
@export var EnergyStorage:float = MaxEnergyStorage
@export var TimeToRecharge:float = 500
@export var RechargeTimer:float = 0
var Recharging:bool = true

var FoodAvailable = MaxFoodSpawn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#-----------------------------------------------------

func _process(delta: float) -> void:
	
	#use this if area and not food pixel
	#if EnergyStorage < 0:
		#Recharging = true
#
	#if Recharging:
		#EnergyStorage += RechargeRate
		#if EnergyStorage == MaxEnergyStorage:
			#Recharging = false
#-----------------------------------------------------
#use this if food pixel and not area
	$"%Label".text = str(FoodAvailable)
	if FoodAvailable > 0:
		var food = FOOD.instantiate()
		var spawnDirection = get_direction()
		food.position = $RigidBody2D.position + spawnDirection*10
		food.apply_central_impulse(spawnDirection*randf_range(0.1*MaxThrownInpulse,MaxThrownInpulse))
		add_child(food)
		FoodAvailable -= 1
	else:
		FoodAvailable -= RechargeRate
		if FoodAvailable < -MaxFoodSpawn*MultToRecharge:
			FoodAvailable = MaxFoodSpawn
			
func get_direction() -> Vector2:
	var angle = randi_range(0,360)
	var direction = Vector2(cos(deg_to_rad(angle)),sin(deg_to_rad(angle)))
	return direction
##-----------------------------------------------------

	
