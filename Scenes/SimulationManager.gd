extends Node

@onready var robot_group := "robot"
var processing := false
const RobotSnapshot := preload("res://Scenes/Robot/robot_snaptshot.gd")

func _physics_process(_delta):
	if not processing:
		var data = get_robot_snapshots()
		var task_callable := Callable(self, "_simulate_robot_logic").bind(data)
		WorkerThreadPool.add_task(
			task_callable,
			false,  # prioridade normal
			"_on_simulation_done"  # nome da função de callback
		)
		processing = true

func get_robot_snapshots() -> Array:
	var snapshots := []
	for robot in get_tree().get_nodes_in_group(robot_group):
		var snap = RobotSnapshot.new()
		snap.id = robot.RobotID
		snap.energy = robot.get_current_energy()
		snap.age = robot.Age
		snap.movement_probs = robot.MovementProbs
		snap.dettach_prob = robot.DettachProbability
		snap.join_count = robot.get_joinedTo_number()
		snap.can_replicate = (robot.ReplicationCount == 0 and snap.join_count >= robot.LimitToReplicate)
		snap.movement_direction = robot.MovementDirection
		snapshots.append(snap)
	return snapshots

func _simulate_robot_logic(robots: Array) -> Array:
	var result := []
	for data in robots:
		var direction_code = Global.weighted_choice(data.movement_probs)
		var dir_dict := {"N": Vector2(0, -1), "S": Vector2(0, 1), "E": Vector2(1, 0), "W": Vector2(-1, 0), "Z": Vector2(0, 0)}
		var direction = dir_dict.get(direction_code, Vector2.ZERO)

		var should_die: bool = (data.energy <= 0 or data.age >= 999)
		var command := {
			"id": data.id,
			"direction": direction,
			"should_die": should_die,
			"should_replicate": data.can_replicate
		}
		result.append(command)
	return result

func _on_simulation_done(result: Array) -> void:
	for cmd in result:
		var bot = get_node_or_null("Robots/" + cmd.id)
		if bot:
			if cmd.should_die:
				bot.die(0)
			else:
				bot.change_direction(cmd.direction)
			if cmd.should_replicate:
				bot.self_replicate()
	processing = false
