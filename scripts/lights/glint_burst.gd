extends Node2D

const DaylightCheck := preload("res://scripts/world/daylight_check.gd")
const MAX_ENERGY := 1.6

var radius := 0.0
var duration := 0.0
var obstacle_mask := 1
var time_left := 0.0

@onready var light: PointLight2D = $Light

func _ready() -> void:
	add_to_group("daylight_fields")

func configure(radius_value: float, duration_value: float, mask: int) -> void:
	radius = radius_value
	duration = duration_value
	obstacle_mask = mask
	time_left = duration_value
	if light == null:
		return
	var texture_width := 256.0
	if light.texture != null:
		texture_width = float(light.texture.get_width())
	light.texture_scale = radius * 2.0 / texture_width
	light.energy = MAX_ENERGY

func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	if light != null:
		light.energy = MAX_ENERGY * clampf(time_left / maxf(duration, 0.001), 0.0, 1.0)

func is_point_lit(point: Vector2) -> bool:
	return DaylightCheck.is_lit(
		get_world_2d().direct_space_state,
		point,
		global_position,
		radius,
		Vector2.ZERO,
		180.0,
		obstacle_mask
	)
