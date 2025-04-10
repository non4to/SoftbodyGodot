extends Node
const BONE = preload("res://Scenes/Robot/bone.gd")

#--------------------------------------
func attach_bodies(boneA:Bone, boneB: Bone) -> void:	
	var joint1: PinJoint2D = PinJoint2D.new()
	var joint2: PinJoint2D = PinJoint2D.new()

	joint1.position = Vector2(0,0)
	joint1.node_a = boneA.get_path()
	joint1.node_b = boneB.get_path()
	joint1.softness = 0.001
	joint1.disable_collision =false
	joint1.name = "body-link"
	boneA.Joined = true
	boneA.JoinedTo = boneB
	boneA.JointDirection = Global.get_direction_vector(boneA,boneB)
	boneA.add_child(joint1)
	
	joint2.position = Vector2(0,0)
	joint2.node_a = boneB.get_path()
	joint2.node_b = boneA.get_path()
	joint2.softness = 0.001
	joint2.disable_collision =false
	joint2.name = "body-link"
	boneB.Joined = true
	boneB.JoinedTo = boneA
	boneB.JointDirection = Global.get_direction_vector(boneB,boneA)
	boneB.add_child(joint2)
	
	boneA.RelatedJoints.append(joint1)
	boneA.RelatedJoints.append(joint2)
	boneB.RelatedJoints.append(joint1)
	boneB.RelatedJoints.append(joint2)
	
	var jointLine:Line2D = Line2D.new()
	jointLine.name = "jointline"
	jointLine.add_point(boneA.global_position/100,0)
	jointLine.add_point(boneB.global_position/100,1)
	jointLine.default_color = Color(255,255,255)
	jointLine.width = 3
	jointLine.z_index = +2
	boneA.add_child(jointLine)
	LogManager.log_event(Global.Step,"[attach_bodies] attachment",boneA.BoneOf,boneA.name,boneB.BoneOf,boneB.name)

#--------------------------------------
func break_joint(bone:Bone, jointLine:Line2D=null) -> void:
	for joint in bone.RelatedJoints:
		if is_instance_valid(joint): joint.free()
	if jointLine: jointLine.free()
	else:
		var jointLine2:Line2D = get_node_or_null(str(str(bone.JoinedTo.get_path())+"/jointline"))
		if is_instance_valid(jointLine2): jointLine2.free()

	call_deferred("reset_variables",bone)
	call_deferred("reset_variables",bone.JoinedTo)
#--------------------------------------
func reset_variables(bone:Bone) -> void:
	bone.Joined = false
	bone.JoinedTo = null
	bone.RelatedJoints.clear()
