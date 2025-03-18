extends Node2D

var robot_id: String
var center_bone: RigidBody2D
var bones = []
var max_power = 100ls

var direction_x = 1
var direction_y = 1
var power_x = 0
var power_y = 0
var current_collisions = 0
#var bone_script = ("res://Scenes/Robot/bone.gd")

## genes: velocity value, energy
## 4 sensors: one of each side.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_robot() #ID to the robot and its bones
	
func _process(delta: float) -> void:
	#print(get_children())
	pass

func _physics_process(delta: float) -> void:	
	pass
	
func start_robot() -> void:
	#Builds an ID to robot and adds robot and its bones to this group
	robot_id = "id_" + str(get_instance_id())
	add_to_group("robot")
	add_to_group(robot_id)
	for bone in get_node("SoftBody2D").get_children():
		if bone.is_class("RigidBody2D") and ("Bone" in bone.name):
			bones.append(bone)	
			bone.add_to_group("bone")
			bone.add_to_group(robot_id)
			#bone.set_script(bone_script)
			#bone.connect("bone_collided_with_robot", _on_bone_collided_with_robot)
			bone.connect("bone_collided", _on_bone_collided)
			bone.connect("bone_collision_finished", _on_bone_collision_finished)
			
func contract(bone:RigidBody2D, in_bone_direction:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,in_bone_direction)
	bone.apply_central_force(direction*withForce)

func contract_top(withForce:float) -> void:
	contract(bones[0],bones[4],withForce)
	#contract(bones[2],bones[0],withForce)

	contract(bones[3],bones[4],withForce)
	#contract(bones[5],bones[3],withForce)
	
	contract(bones[6],bones[4],withForce)
	#contract(bones[8],bones[6],withForce)

func contract_blue(withForce:float)	-> void:
	contract(bones[6],bones[8],withForce)
	#contract(bones[27],bones[22],withForce)
	
func attach_bodies(my_bone:RigidBody2D, other_bone: RigidBody2D, side:String) -> void:
	print(my_bone,other_bone)
	var point1 = self.position
	var point2 = self.position
	var joint1 = PinJoint2D.new()
	var joint2 = PinJoint2D.new()

	
	if side == "left":
		point1 = Vector2(0,12.5) 
		point2 = Vector2(0,37.5)
	elif side == "right":
		point1 = Vector2(50,25)
		point2 = Vector2(50,50)
	elif side == "top":
		point1 = Vector2(12.5,0)
		point2 = Vector2(37.5,0)
	elif side == "bot":
		point1 = Vector2(25,50)
		point2 = Vector2(50,50)
		
	joint1.position = point1
	joint2.position = point2
	
	joint1.node_a = my_bone.get_path()
	joint1.node_b = other_bone.get_path()
	joint2.node_a = my_bone.get_path()
	joint2.node_b = other_bone.get_path()
	
	joint1.scale = Vector2(1.2,1.2)
	joint2.scale = Vector2(1.2,1.2)
	
	joint1.softness = 0.001
	joint2.softness = 0.001
	
	my_bone.add_child(joint1)
	my_bone.add_child(joint2)
	
func get_direction_vector(fromA:RigidBody2D,toB:RigidBody2D) -> Vector2:
	var direction_vector = Vector2(0,0)
	direction_vector = (toB.global_position-fromA.global_position).normalized()	
	return direction_vector

func _on_timer_timeout() -> void:
	#contract_blue(mult*max_power)
	#contract_top(mult*max_power)
	if randf() < 0.4:
		if randf() < 0.5:
			direction_x *= -1
		if randf() > 0.5:
			direction_y *= -1
		power_x = max_power#randi_range(1000, max_power)
		power_y = max_power#randi_range(1000, max_power)
		$SoftBody2D.apply_impulse(Vector2(direction_x*power_x, direction_y*power_y))
#func _on_bone_collided_with_robot(my_bone:RigidBody2D,other_bone:RigidBody2D):
	#print(my_bone, other_bone)
	
func _on_bone_collided(my_bone:RigidBody2D,other_thing:Node):
	if (other_thing.is_in_group("bone"))and not(other_thing.is_in_group(robot_id)):
		pass
		#print("collidi com outro robo!")
	#print("collidi com algo!", other_thing)
	current_collisions += 1
	#direction *= -1
	#print(my_bone, other_thing)

func _on_bone_collision_finished(my_bone:RigidBody2D,other_thing:Node):
	#print(other_thing)
	current_collisions -= 1

func _on_topleft_body_entered(body: Node2D) -> void:
	pass
	#if (body.is_in_group("bone")) and not(body.is_in_group(robot_id)):
		#self.attach_bodies($"SoftBody2D/Bone-0",body,"left")

func _on_topright_body_entered(body: Node2D) -> void:
	pass
	#if (body.is_in_group("bone")) and not(body.is_in_group(robot_id)):
		#self.attach_bodies($"SoftBody2D/Bone-6",body,"right")
		#print(body, self)
