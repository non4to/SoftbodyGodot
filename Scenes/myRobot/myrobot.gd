extends Node2D
var rigid1_pos = Vector2(0,0)
var rigid2_pos = Vector2(0,0)

var max_force = 500
var accumulated_force = 0
var charge_rate = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$rigid1.freeze_mode=1
	$rigid2.freeze_mode=1
	#$DampedSpringJoint2D.length=300
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dist = $rigid1.position.x - $rigid2.position.x
	print(dist)
	pass	

	#print("r1 freeze: ",$rigid1.freeze)
	#print("r2 freeze: ",$rigid2.freeze)	
	#print($DampedSpringJoint2D.length)
	#if (rigid1_pos < $rigid1.position-Vector2(1,1)) or (rigid1_pos > $rigid1.position+Vector2(1,1)):
		#rigid1_pos = $rigid1.position
		#print("R1: ",rigid1_pos)	
	#if (rigid2_pos < $rigid2.position-Vector2(1,1)) or (rigid2_pos > $rigid2.position+Vector2(1,1)):
		#rigid2_pos = $rigid2.position
		#print("R2: ",rigid2_pos)	

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		$rigid2.apply_force(Vector2(150, 0))
		#$rigid1.apply_force(Vector2(-150, 0))
		accumulated_force += min(accumulated_force + charge_rate * delta, max_force)
		#print("Accumulated Force = ",accumulated_force)
	elif Input.is_action_just_released("ui_left"):
		accumulated_force = 0
	elif Input.is_action_pressed("ui_right"):
		$rigid1.apply_force(Vector2(-150, 0))
		accumulated_force += min(accumulated_force + charge_rate * delta, max_force)
		#print("Accumulated Force = ",accumulated_force)
	elif Input.is_action_just_released("ui_right"):
		accumulated_force = 0
	
	

	
