extends Camera2D

@export var target_path: NodePath = ^"../Keeper"
@export var follow_speed_path := "camera.follow_speed"

var target_override: Node2D = null

func set_target(value: Node2D) -> void:
	target_override = value

func _physics_process(delta: float) -> void:
	var target := target_override if is_instance_valid(target_override) else get_node_or_null(target_path)
	if target == null:
		return
	var speed := float(Data.require_value(follow_speed_path))
	var weight := 1.0 - exp(-speed * delta)
	global_position = global_position.lerp(target.global_position, weight)
