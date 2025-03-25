extends Node2D
@export var SpringLen:float
@export var SpringRestLen:float
@export var SpringStiffness:float
@export var SpringDamping:float

var ForceToMove: Vector2 = Vector2(0,5)
var Step:int = 0
var NoMovementStep: int = 100

func _physics_process(delta: float) -> void:	
	updating_springs()	

	$Label.text = str(Step)
	Step += 1
	if Step > NoMovementStep:
		move_block($A,Vector2(0,0))
		move_block($B,Vector2(0,0))
	else:
		move_block($A,Vector2(-5,0))
		move_block($B,Vector2(5,0))
		
	if Step > NoMovementStep*2.5:
		Step = 0



func updating_springs():
	$"%A-DampedSpringJoint2D".length = SpringLen
	$"%A-DampedSpringJoint2D".rest_length = SpringRestLen
	$"%A-DampedSpringJoint2D".stiffness = SpringStiffness
	$"%A-DampedSpringJoint2D".damping = SpringDamping
	##
	$"%B-DampedSpringJoint2D".length = SpringLen
	$"%B-DampedSpringJoint2D".rest_length = SpringRestLen
	$"%B-DampedSpringJoint2D".stiffness = SpringStiffness
	$"%B-DampedSpringJoint2D".damping = SpringDamping
	##
	$Line2D.set_point_position(0,$A.position)
	$Line2D.set_point_position(1,$B.position)
	
	
func move_block(block:RigidBody2D,force:Vector2):
	block.apply_central_impulse(force)
