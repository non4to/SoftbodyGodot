extends Node
const Bone = preload("res://Scenes/Robot/bone.gd")


func attach_bodies(BoneA:RigidBody2D, BoneB: RigidBody2D) -> void:	
	var joint1: PinJoint2D = PinJoint2D.new()
	var joint2: PinJoint2D = PinJoint2D.new()

	joint1.position = Vector2(0,0)
	joint1.node_a = BoneA.get_path()
	joint1.node_b = BoneB.get_path()
	joint1.softness = 0.001
	joint1.disable_collision =false
	joint1.name = "body-link"
	BoneA.Joined = true
	BoneA.JoinedTo = BoneB
	BoneA.JointDirection = Global.get_direction_vector(BoneA,BoneB)
	BoneA.add_child(joint1)
	
	joint2.position = Vector2(0,0)
	joint2.node_a = BoneB.get_path()
	joint2.node_b = BoneA.get_path()
	joint2.softness = 0.001
	joint2.disable_collision =false
	joint2.name = "body-link"
	BoneB.Joined = true
	BoneB.JoinedTo = BoneA
	BoneB.JointDirection = Global.get_direction_vector(BoneB,BoneA)
	BoneB.add_child(joint2)
	
	BoneA.RelatedJoints.append(joint1)
	BoneA.RelatedJoints.append(joint2)
	BoneB.RelatedJoints.append(joint1)
	BoneB.RelatedJoints.append(joint2)
	
	var jointLine:Line2D = Line2D.new()
	jointLine.name = "joint"
	jointLine.add_point(BoneA.global_position/100,0)
	jointLine.add_point(BoneB.global_position/100,1)
	jointLine.default_color = Color(255,255,255)
	jointLine.width = 3
	jointLine.z_index = +1
	BoneA.add_child(jointLine)
#--------------------------------------
func break_joints(bone:Bone) -> void:
	for joint in bone.RelatedJoint:
		if is_instance_valid(joint):
			joint.queue_free()
	bone.Joined = false
	bone.JoinedTo = null
	bone.RelatedJoints.clear()

			
