extends Area2D

@export var npc_id := "odile"
@export var display_name := "Odile"
@export var stubborn := false
@export var body_color := Color("#D9A066")

var home := Vector2.ZERO
var _destination := Vector2.ZERO
var _walking := false

func _ready() -> void:
	add_to_group("townsfolk")
	home = global_position
	_destination = home
	Events.dusk_started.connect(_on_dusk)
	Events.dawn.connect(_on_dawn)
	Events.house_hollowed.connect(_on_house_hollowed)
	Events.house_cleared.connect(_on_house_cleared)

func _on_dusk() -> void:
	if stubborn:
		return
	var hall := get_tree().get_first_node_in_group("hall") as Node2D
	if hall != null:
		_walk_to(hall.global_position)

func _on_dawn() -> void:
	var house := _house()
	if house != null and not house.can_return():
		_walk_to_hall()
	else:
		_walk_to(home)

func _on_house_hollowed(house_id: String) -> void:
	if house_id == npc_id:
		_walk_to_hall()

func _on_house_cleared(house_id: String) -> void:
	if house_id == npc_id:
		_walk_to(home)

func _house() -> Node:
	for node in get_tree().get_nodes_in_group("houses"):
		if String(node.get("npc_id")) == npc_id:
			return node
	return null

func _walk_to_hall() -> void:
	var hall := get_tree().get_first_node_in_group("hall") as Node2D
	if hall != null:
		_walk_to(hall.global_position)

func _walk_to(point: Vector2) -> void:
	_destination = point
	_walking = true

func _physics_process(delta: float) -> void:
	if not _walking:
		return
	var offset := _destination - global_position
	if offset.length() <= float(Data.require_value("townsfolk.arrive_radius")):
		global_position = _destination
		_walking = false
		return
	global_position += offset.normalized() * float(Data.require_value("townsfolk.walk_speed")) * delta

func person_id() -> String:
	return npc_id

func capture_state() -> Dictionary:
	return {
		"id": person_id(),
		"position": [global_position.x, global_position.y],
		"home": [home.x, home.y],
		"destination": [_destination.x, _destination.y],
		"walking": _walking,
	}

func restore_state(state: Dictionary) -> void:
	global_position = _read_vector(state.get("position", []), global_position)
	home = _read_vector(state.get("home", []), home)
	_destination = _read_vector(state.get("destination", []), _destination)
	_walking = bool(state.get("walking", _walking))
	queue_redraw()

func _read_vector(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback

func interact() -> String:
	var box := get_tree().get_first_node_in_group("dialogue_boxes")
	if box != null:
		box.open(npc_id)
	return ""

func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2(0, 0), Vector2(9, 3.5)), Color("#141B29"))
	draw_rect(Rect2(-7, -18, 14, 18), body_color)
	draw_circle(Vector2(0, -22), 7.0, Color("#F4F7FA"))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
