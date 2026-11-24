extends Camera2D

@export var target_path: NodePath = ^"../Keeper"
@export var follow_speed_path := "camera.follow_speed"

func _physics_process(delta: float) -> void:
	var target := get_node_or_null(target_path)
	if target == null:
		return
	var speed := float(Data.require_value(follow_speed_path))
	var weight := 1.0 - exp(-speed * delta)
	global_position = global_position.lerp(target.global_position, weight)
