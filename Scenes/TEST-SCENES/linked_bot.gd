extends Node2D

@export var Softness:float = 0
var ForceToMove: Vector2 = Vector2(0,5)
var Step:int = 0
var NoMovementStep: int = 100

func _physics_process(delta: float) -> void:	
	updating_joints()	

	$Label.text = str(Step)
	Step += 1
	if Step > NoMovementStep:
		move_block($A,Vector2(0,0))
		move_block($B,Vector2(0,0))
	else:
		move_block($A,Vector2(2,2))
		move_block($B,Vector2(-2,-2))
		
	if Step > NoMovementStep*2.5:
		Step = 0



func updating_joints():
	$"A/A-PinJoint2D".softness = Softness
	$"B/B-PinJoint2D".softness = Softness
	##
	$Line2D.set_point_position(0,$A.position)
	$Line2D.set_point_position(1,$B.position)
	
	
func move_block(block:RigidBody2D,force:Vector2):
	block.apply_central_impulse(force)
