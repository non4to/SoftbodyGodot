extends Node2D
var robot_id: String
var center_bone: RigidBody2D
var bones_list = []
var max_power = 500
var bone_script = ("res://Scenes/Robot/bone.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_robot() #ID to the robot and its bones
	center_bone = $"%Bone-4"
	
func start_robot() -> void:
	#Builds an ID to robot and adds robot and its bones to this group
	robot_id = "id_" + str(get_instance_id())
	add_to_group("robot")
	add_to_group(robot_id)
	for bone in get_node("SoftBody2D").get_children():
		if bone.is_class("RigidBody2D") and ("Bone" in bone.name):
			bones_list.append(bone)	
			bone.add_to_group("bone")
			bone.add_to_group(robot_id)
			bone.set_script(bone_script)
			bone.connect("bone_collided_with_robot", _on_bone_collided_with_robot)
			bone.connect("bone_collided", _on_bone_collided)
			
func _process(delta: float) -> void:
	var robot_center = $"%Bone-4".global_position
	#print_tree()
	#print($RigidBody2D.position)
	
func _physics_process(delta: float) -> void:	
	
	#var power = Vector2(randf_range(-max_power,max_power),randf_range(-max_power,0))  # Intensidade do impulso
	#self.move(delta,power)
	var mult = 50
	if Input.is_action_just_released("ui_up"):
		#contract($"%Bone-0",$"%Bone-2",mult*max_power)
		contract($"%Bone-6",$"%Bone-8",1.5*mult*max_power)
		contract($"%Bone-3",$"%Bone-5",mult*max_power)
		#contract($"%Bone-5",$"%Bone-3",mult*max_power)
#
		#contract($"%Bone-6",$"%Bone-8",mult*max_power)
		#contract($"%Bone-8",$"%Bone-6",mult*max_power)

		#apply_force($"%Bone-3",self.get_direction_vector($"%Bone-3",$"%Bone-5"),mult*max_power)

		#apply_force($"%Bone-1",self.get_direction_vector($"%Bone-1",center_bone),mult*max_power)
		#apply_force($"%Bone-5",self.get_direction_vector($"%Bone-5",center_bone),mult*max_power)
		#apply_force($"%Bone-6",self.get_direction_vector($"%Bone-6",$"%Bone-8"),mult*max_power)
		#apply_force($"%Bone-10",self.get_direction_vector($"%Bone-10",$"%Bone-12"),mult*max_power)
		#apply_force($"%Bone-11",self.get_direction_vector($"%Bone-11",$"%Bone-12"),mult*max_power)
		#apply_force($"%Bone-15",self.get_direction_vector($"%Bone-15",$"%Bone-12"),mult*max_power)
		#apply_force($"%Bone-16",self.get_direction_vector($"%Bone-16",$"%Bone-12"),mult*max_power)
		#apply_force($"%Bone-20",self.get_direction_vector($"%Bone-20",$"%Bone-12"),mult*max_power)
		#apply_force($"%Bone-21",self.get_direction_vector($"%Bone-21",$"%Bone-12"),mult*max_power)

		#$"%left".apply_central_force((Vector2(+mult*max_power,0)))
	if Input.is_action_pressed("ui_right"):
		#$"%right".apply_central_force((Vector2(-mult*max_power,0)))

		#$"%Bone-20".apply_central_force(Vector2(5*max_power, 0))
		#$"%Bone-21".apply_central_force(Vector2(5*max_power, 0))
		$"%Bone-22".apply_central_force(Vector2(-mult*max_power, 0))
		#$"%Bone-23".apply_central_force(Vector2(5*max_power, 0))
		#$"%Bone-24".apply_central_force(Vector2(5*max_power, 0))

func contract(bone:RigidBody2D, in_bone_direction:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,in_bone_direction)
	bone.apply_central_force(direction*withForce)

func _on_bone_collided_with_robot(my_bone:RigidBody2D,other_bone:RigidBody2D):
	print(my_bone, other_bone)
	
func _on_bone_collided(my_bone:RigidBody2D,other_thing:StaticBody2D):
	print(my_bone, other_thing)



func get_direction_vector(fromA:RigidBody2D,toB:RigidBody2D) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector
	
