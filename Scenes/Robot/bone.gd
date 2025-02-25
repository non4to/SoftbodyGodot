extends RigidBody2D
signal bone_collided_with_robot(myself, collider)
signal bone_collided(myself, collider)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 30
	connect("body_entered", _on_body_entered)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(collider):
	print("whoa")
	var my_id = self.get_groups()[1]

	if (collider.is_in_group("bone"))and not(collider.is_in_group(my_id)):
		bone_collided_with_robot.emit(self,collider)

	if collider:
		bone_collided.emit(self,collider)
