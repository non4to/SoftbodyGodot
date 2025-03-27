extends RigidBody2D
var robot_id								# id of robot this bone belongs to
var Joined:bool = false						# if this bone is joint to something else or not
var JoinedTo:RigidBody2D					# bone is joint to
var RelatedJoints:Array[PinJoint2D]=[]		# All existing joints to other robots relates with this bone
var AngleVariationToBreakJoint:float=10		# The angle between the movementDirection of the bots joined has to be between 180-this and 180+this for the joints to break
var JointDirection:Vector2=Vector2(0,0)     # self explanatory

signal bone_collided(myself:RigidBody2D, collider:Node)
signal bone_exited(myself:RigidBody2D, collider:Node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 30
	connect("body_entered", _on_body_entered)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Joined and is_instance_valid(JoinedTo):
		var thisBot = self.get_parent().get_parent()
		var jointAngleDif = abs(rad_to_deg(thisBot.MovementDirection.angle_to(JointDirection)))
		var otherBot = JoinedTo.get_parent().get_parent()
		var velAngleDif = abs(rad_to_deg(thisBot.MovementDirection.angle_to(otherBot.MovementDirection)))
		var jointLine:Line2D = get_node_or_null("joint")
		if (jointAngleDif > (180-AngleVariationToBreakJoint)) and (velAngleDif > (180-AngleVariationToBreakJoint)):
			for joint in RelatedJoints:
				if is_instance_valid(joint):
					joint.queue_free()
			Joined = false	
			RelatedJoints.clear()
			for joint in JoinedTo.RelatedJoints:
				if is_instance_valid(joint):
					joint.queue_free()
			JoinedTo.Joined = false
			JoinedTo.RelatedJoints.clear()
			if jointLine:
				jointLine.queue_free()
			else:
				var jointLine2:Line2D = JoinedTo.get_node_or_null("joint")
				if jointLine2:
					jointLine2.queue_free()
				
		else:
			if jointLine:			
				var localPosSelf = jointLine.to_local(global_position)
				var localPosJoinedTo = jointLine.to_local(JoinedTo.global_position)
				jointLine.set_point_position(0, localPosSelf)
				jointLine.set_point_position(1, localPosJoinedTo)

func break_joint() -> bool:
	var breakJoint:bool = false	
	pass
		
	
	return breakJoint

func _on_body_entered(collider:Node): #emits bone collided, if any bone collided with anything outside the robot.
	var my_id = self.get_groups()[1]
	if not(collider.is_in_group(my_id)):
		bone_collided.emit(self,collider)
	
func _on_body_exited(collider:Node): #emits bone exited, if any bone exited anything outside the robot.
	var my_id = self.get_groups()[1]
	if not(collider.is_in_group(my_id)):
		bone_exited.emit(self,collider)
	
		
