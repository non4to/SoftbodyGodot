extends Node
const JOINT = preload("res://Scenes/Robot/joint.gd")

func _init() -> void:
    Global.JointNumber += 1

func _exit_tree() -> void:
    Global.JointNumber -= 1