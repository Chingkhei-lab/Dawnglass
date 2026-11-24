extends Node2D

@export var npc_id := "odile"
@export var wall_color := Color("#665144")
@export var roof_color := Color("#4D3B36")
@export var door_color := Color("#241F25")
@export var nest_color := Color("#080B12")

var _empty_tonight := false
var _was_lit := false

func _ready() -> void:
	add_to_group("houses")
	if not GameState.houses.has(npc_id):
		GameState.houses[npc_id] = "home"
	Events.night_started.connect(_on_night_started)
	Events.dawn.connect(_on_dawn)
	queue_redraw()

func capture_state() -> Dictionary:
	return {
		"id": npc_id,
		"empty_tonight": _empty_tonight,
		"was_lit": _was_lit,
	}

func restore_state(state: Dictionary) -> void:
	_empty_tonight = bool(state.get("empty_tonight", _empty_tonight))
	_was_lit = bool(state.get("was_lit", _was_lit))
	queue_redraw()

func state() -> String:
	return String(GameState.houses.get(npc_id, "home"))

func is_hollow() -> bool:
	return state() == "hollow"

func can_return() -> bool:
	return not is_hollow()

func _physics_process(_delta: float) -> void:
	if Clock.phase == Clock.PHASE_NIGHT:
		if _is_lit():
			_was_lit = true
	elif Clock.phase == Clock.PHASE_DAY and is_hollow():
		_try_clear()

func _on_night_started() -> void:
	_empty_tonight = _family_is_away()
	_was_lit = false

func _on_dawn() -> void:
	if is_hollow():
		return
	# PROVISIONAL: see GAME_BIBLE §7.3; any light during an empty night prevents hollowing.
	if _empty_tonight and not _was_lit:
		GameState.houses[npc_id] = "hollow"
		queue_redraw()
		Events.house_hollowed.emit(npc_id)
	else:
		GameState.houses[npc_id] = "home"
		queue_redraw()

func _try_clear() -> void:
	if not _lantern_near(float(Data.require_value("houses.clear_radius"))):
		return
	# PROVISIONAL: see GAME_BIBLE §7.3; the lantern and a Glint must overlap the house by day.
	for burst in get_tree().get_nodes_in_group("glint_bursts"):
		if burst.is_point_lit(_nest_center()):
			GameState.houses[npc_id] = "home"
			queue_redraw()
			Events.house_cleared.emit(npc_id)
			return

func _is_lit() -> bool:
	if _lantern_near(float(Data.require_value("houses.light_radius"))):
		return true
	for field in get_tree().get_nodes_in_group("daylight_fields"):
		if field.has_method("is_point_lit") and field.is_point_lit(_nest_center()):
			return true
	return false

func _lantern_near(radius: float) -> bool:
	for node in get_tree().get_nodes_in_group("keepers"):
		var keeper := node as Node2D
		if keeper != null and keeper.has_method("is_lantern_on") and keeper.is_lantern_on():
			if keeper.global_position.distance_to(global_position) <= radius:
				return true
	return false

func _family_is_away() -> bool:
	var radius := float(Data.require_value("houses.empty_radius"))
	for node in get_tree().get_nodes_in_group("townsfolk"):
		if String(node.get("npc_id")) == npc_id:
			var person := node as Node2D
			return person != null and person.global_position.distance_to(global_position) > radius
	return false

func _nest_center() -> Vector2:
	return global_position + Vector2(0, 28)

func _draw() -> void:
	var hollow := is_hollow()
	var walls := Color("#18202D") if hollow else wall_color
	var roof := Color("#101520") if hollow else roof_color
	var door := Color("#080B12") if hollow else door_color
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(0, -20)]), roof)
	draw_rect(Rect2(-28, 0, 56, 34), walls)
	draw_rect(Rect2(-8, 16, 16, 18), door)
	var window_color := Color("#080B12") if hollow else Color(1, 0.721, 0.302, 1)
	draw_rect(Rect2(-20, 10, 8, 8), window_color)
	draw_rect(Rect2(12, 10, 8, 8), window_color)
	if hollow:
		_draw_nest()

func _draw_nest() -> void:
	draw_colored_polygon(_ellipse(Vector2(0, 30), Vector2(23, 6)), nest_color)
	for offset in [Vector2(-12, 24), Vector2(0, 28), Vector2(12, 24)]:
		draw_colored_polygon(_ellipse(offset, Vector2(6, 2.5)), nest_color)
		draw_circle(offset + Vector2(0, -5), 3.5, nest_color)

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
