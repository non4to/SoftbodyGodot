extends RigidBody2D

var EnergyGiven = 3
var SpoilTimer = 500
var StepToSpoil = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:	
	StepToSpoil += 1
	if StepToSpoil > SpoilTimer:
		self.queue_free()
	elif StepToSpoil > 0.9*SpoilTimer:
		$ColorRect.color = Color("black")
	elif StepToSpoil > 0.66*SpoilTimer:
		$ColorRect.color = Color("brown")
	elif StepToSpoil > 0.33*SpoilTimer:
		$ColorRect.color = Color("orange")
