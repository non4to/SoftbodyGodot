extends Node2D

const FOOD = preload("res://Scenes/Food/food.tscn")
@export var MaxFoodSpawn = 15
@export var RechargeRate = 1
@export var MultToRecharge = 15
@export var MaxThrownInpulse = 150


var FoodAvailable = MaxFoodSpawn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#-----------------------------------------------------

func _process(delta: float) -> void:
	$"%Label".text = str(FoodAvailable)
	if FoodAvailable > 0:
		var food = FOOD.instantiate()
		var spawnDirection = get_direction()
		food.position = $RigidBody2D.position + spawnDirection*10
		food.apply_central_impulse(spawnDirection*randf_range(0.2*MaxThrownInpulse,MaxThrownInpulse))
		add_child(food)
		FoodAvailable -= 1
	else:
		FoodAvailable -= RechargeRate
		if FoodAvailable < -MaxFoodSpawn*MultToRecharge:
			FoodAvailable = MaxFoodSpawn
#-----------------------------------------------------
func get_direction() -> Vector2:
	var angle = randi_range(0,360)
	var direction = Vector2(cos(deg_to_rad(angle)),sin(deg_to_rad(angle)))
	return direction
	
