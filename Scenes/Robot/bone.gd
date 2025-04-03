extends RigidBody2D

class_name Bone

var CanJoin:bool = true
var Joined:bool = false						# if this bone is joint to something else or not
var JoinedTo:Bone = null					# bone is joint to
var RelatedJoints:Array[PinJoint2D]=[]		# All existing joints to other robots relates with this bone
var AngleVariationToBreakJoint:float=10		# The angle between the movementDirection of the bots joined has to be between 180-this and 180+this for the joints to break
var JointDirection:Vector2=Vector2(0,0)     # self explanatory

signal bone_collided(myself:RigidBody2D, collider:Node)
signal bone_exited(myself:RigidBody2D, collider:Node)
# signal joint_broke(myself:RigidBody2D, otherBot:Node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 30
	connect("body_entered", _on_body_entered)

func _on_body_entered(collider:Node): #emits bone collided, if any bone collided with anything outside the robot.
	var my_id = self.get_groups()[1]
	if not(collider.is_in_group(my_id)):
		bone_collided.emit(self,collider)
	
func _on_body_exited(collider:Node): #emits bone exited, if any bone exited anything outside the robot.
	var my_id = self.get_groups()[1]
	if not(collider.is_in_group(my_id)):
		bone_exited.emit(self,collider)
	

		
