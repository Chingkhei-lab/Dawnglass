extends Node2D

@export var villager_id := "villager"

var taken := false

func _ready() -> void:
	add_to_group("persons")

func person_id() -> String:
	return villager_id

func capture_state() -> Dictionary:
	return {
		"id": person_id(),
		"position": [global_position.x, global_position.y],
		"taken": taken,
	}

func restore_state(state: Dictionary) -> void:
	var position_value: Variant = state.get("position", [])
	if position_value is Array and position_value.size() >= 2:
		global_position = Vector2(float(position_value[0]), float(position_value[1]))
	taken = bool(state.get("taken", taken))
	queue_redraw()

func is_takeable() -> bool:
	return not taken

func take_shadow() -> void:
	if taken:
		return
	taken = true
	GameState.mark_sleeper(villager_id)
	Events.person_taken.emit()
	queue_redraw()

func _draw() -> void:
	if taken:
		draw_colored_polygon(_ellipse(Vector2(0, -4), Vector2(12, 3)), Color("#141B29"))
		draw_rect(Rect2(-12, -10, 24, 6), Color("#5C7891"))
		return
	draw_colored_polygon(_ellipse(Vector2(0, 0), Vector2(9, 3.5)), Color("#141B29"))
	draw_rect(Rect2(-7, -18, 14, 18), Color("#7CA5B8"))
	draw_circle(Vector2(0, -22), 7.0, Color("#F4F7FA"))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
