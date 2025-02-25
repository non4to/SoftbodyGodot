extends RigidBody2D

const LEFT_BONES = ["SoftBody2D/Bone-0","SoftBody2D/Bone-1","SoftBody2D/Bone-2"]
const TOP_BONES = ["SoftBody2D/Bone-0","SoftBody2D/Bone-3","SoftBody2D/Bone-6"]
const RIGHT_BONES = ["SoftBody2D/Bone-6","SoftBody2D/Bone-7","SoftBody2D/Bone-8"]
const BOT_BONES = ["SoftBody2D/Bone-2","SoftBody2D/Bone-5","SoftBody2D/Bone-8"]

const STANDARD_SPEED = 150
const JUMP_VELOCITY = -200.0
const JUMP_CHANCE = 0.8

var timer = 0
var direction = 1
var attach = true
var is_dashing = false

var left_attached = false
var right_attached = false
var top_attached = false
var bot_attached = false
var attached_to = []

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 50
	# Ativando a gravidade interna do RigidBody2D
	gravity_scale = 1.0 
	for bone in %SoftBody2D.get_children(): #connecting signals
		if bone.is_class("RigidBody2D"):
			bone.connect("bone_collided_with_robot", _on_bone_collided_with_robot)
			bone.connect("bone_collided", _on_bone_collided)
	#####	

func _process(delta: float) -> void:
	pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	pass
	#var speed = STANDARD_SPEED
#
#
	## Change direction randomly
	#timer += 1
	#if timer>90:
		#timer = 0
		#if randf()<0.5:
			#direction *= -1
			#
		#
	#
	#
	#
	##jump_timer += 1
	##if jump_timer > 30:
		##jump_timer = 0
		##
			##linear_velocity.y = JUMP_VELOCITY
	#if is_dashing:
		#speed *= 3
		#is_dashing = false
			#
			#
	#linear_velocity.x = direction * speed

func _input(event:InputEvent):
	if Input.is_action_pressed("dash"):
		is_dashing = true
	
func _on_bone_collided_with_robot(myself, collider):
	#Bone collided with a bone from other robot
	#print("Bone collided with robot!")
	#direction *= -1
	pass

func _on_bone_collided(myself, collider):
	#Bone collided with anything else
	#print("Collided with ",collider)
	if collider.is_in_group("wall"):
		direction *= -1

func _on_left_sensor_body_entered(body: Node2D) -> void:
	#Left sensor sees a collision
	if not self.collided_with_me(body):
		if (attach)and(not left_attached)and(body.name=="Bone-4")and(body not in (attached_to)):
			print("Left collision with ",body)
			attached_to.append(body)
			self.attach_bodies(body,"left")
			left_attached = true

func _on_right_sensor_body_entered(body: Node2D) -> void:
	#Right sensor sees a collision	
	if not self.collided_with_me(body):
		if (attach)and(not right_attached)and(body.name=="Bone-4")and(body not in (attached_to)):
			print("Right collision with ",body)
			attached_to.append(body)
			self.attach_bodies(body,"right")
			right_attached = true

func _on_top_sensor_body_entered(body: Node2D) -> void:
	#Top sensor sees a collision	
	#print(body)
	if not self.collided_with_me(body):
		if (attach)and(not top_attached)and(body.name=="Bone-4")and(body not in (attached_to)):
			print("Top collision with ",body)
			attached_to.append(body)
			self.attach_bodies(body,"top")
			top_attached = true

func _on_bot_sensor_body_entered(body: Node2D) -> void:
	#print(body)
	if not self.collided_with_me(body):
		if (attach)and(not bot_attached)and(body.name=="Bone-4")and(body not in (attached_to)):
			print("Top collision with ",body)
			attached_to.append(body)
			self.attach_bodies(body,"bot")
			bot_attached = true


func collided_with_me(body: Node2D) -> bool:
	var my_id = self.get_groups()[1]
	if body.is_in_group(my_id):
		return true
	else: return false
	
func attach_bodies(body: Node2D, side:String) -> void:
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
	
	joint1.node_a = self.get_path()
	joint1.node_b = body.get_path()
	joint2.node_a = self.get_path()
	joint2.node_b = body.get_path()
	
	joint1.scale = Vector2(1.2,1.2)
	joint2.scale = Vector2(1.2,1.2)

	
	add_child(joint1)
	add_child(joint2)
		
	
	
	
	
