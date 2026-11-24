extends Node2D

const DaylightCheck := preload("res://scripts/world/daylight_check.gd")

var radius := 0.0
var max_radius := 0.0
var duration := 1.0
var band := 14.0
var obstacle_mask := 2

var _time := 0.0

func _ready() -> void:
	add_to_group("daylight_fields")

func configure(radius_value: float, duration_value: float, band_value: float, mask: int) -> void:
	max_radius = radius_value
	duration = maxf(duration_value, 0.001)
	band = band_value
	obstacle_mask = mask

func _physics_process(delta: float) -> void:
	_time += delta
	radius = max_radius * clampf(_time / duration, 0.0, 1.0)
	queue_redraw()
	if _time >= duration:
		queue_free()

func is_point_lit(point: Vector2) -> bool:
	if absf(global_position.distance_to(point) - radius) > band:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, point, obstacle_mask)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.96, 0.82, 0.4), maxf(band * 0.5, 2.0))
