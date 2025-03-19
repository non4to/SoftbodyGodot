extends Node2D

var bones = []
const centerBoneIndex = 4      #Which is the bone in the center of the robot -> Force is applied on it
const maxForce = 1000          #Maximum Force possible
const maxEnergy = 100          #Maximum Energy possible
const metabolism = 1           #Energy cost of staying alive ah ah ah
const movingEnergyMult = 0.005 #Multiply this by the Force of the movement to obtain the Energy Cost

var robotID: String
var gene: int
var energy: int

var direction_x = 1
var direction_y = 1
var power_x = 0
var power_y = 0
var current_collisions = 0

## genes: velocity value, energy
## 4 sensors: one of each side.

# Called when the node enters the scene tree for the first time.

func _init(gene:int=0b0) -> void:
	self.gene = gene
	if self.gene == 0b0: 
		self.gene = 0b1111

func _ready() -> void:
	start_robot() #ID to the robot and its bones
	print(gene)
	
func _process(delta: float) -> void:
	#print($SoftBody2D.get_center_body())
	#var binario = 0b1101101010101111  # Número binário
	#var inteiro_64 = int(binario)
#
	#print("Binário:", binario)  # Exibe o número em base 10
	#print("Convertido para int64:", inteiro_64)
	pass

func _physics_process(delta: float) -> void:	
	pass
	metabolize()
	if randf() < 0.5:
		if randf() < 0.05:
			direction_x *= -1
		if randf() > 0.05:
			direction_y *= -1
		power_x = maxForce#randi_range(1000, maxForce)
		power_y = maxForce#randi_range(1000, maxForce)
		bones[centerBoneIndex].apply_central_force(Vector2(direction_x*power_x, direction_y*power_y))
	
func start_robot() -> void:
	#Builds an ID to robot and adds robot and its bones to this group
	robotID = "id_" + str(get_instance_id())
	add_to_group("robot")
	add_to_group(robotID)
	for bone in get_node("SoftBody2D").get_children():
		if bone.is_class("RigidBody2D") and ("Bone" in bone.name):
			bones.append(bone)	
			bone.add_to_group("bone")
			bone.add_to_group(robotID)
			#bone.set_script(bone_script)
			#bone.connect("bone_collided_with_robot", _on_bone_collided_with_robot)
			bone.connect("bone_collided", _on_bone_collided)
			bone.connect("bone_collision_finished", _on_bone_collision_finished)

func metabolize() -> void:
	self.energy -= metabolism

func contract(bone:RigidBody2D, in_bone_direction:RigidBody2D, withForce:float) -> void:
	var direction = self.get_direction_vector(bone,in_bone_direction)
	bone.apply_central_force(direction*withForce)

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
	pass
	#contract_blue(mult*maxForce)
	#contract_top(mult*maxForce)
	
		#$SoftBody2D.apply_impulse(Vector2(direction_x*power_x, direction_y*power_y))
#func _on_bone_collided_with_robot(my_bone:RigidBody2D,other_bone:RigidBody2D):
	#print(my_bone, other_bone)
	
func _on_bone_collided(my_bone:RigidBody2D,other_thing:Node):
	if (other_thing.is_in_group("bone"))and not(other_thing.is_in_group(robotID)):
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
	#if (body.is_in_group("bone")) and not(body.is_in_group(robotID)):
		#self.attach_bodies($"SoftBody2D/Bone-0",body,"left")

func _on_topright_body_entered(body: Node2D) -> void:
	pass
	#if (body.is_in_group("bone")) and not(body.is_in_group(robotID)):
		#self.attach_bodies($"SoftBody2D/Bone-6",body,"right")
		#print(body, self)
