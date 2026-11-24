extends Node2D

@export var columns := 3
@export var spacing := Vector2(44.0, 54.0)

var _occupants := {}

func _ready() -> void:
	add_to_group("chapel_beds")
	Events.dawn.connect(_on_dawn)
	Events.state_loaded.connect(_on_state_loaded)
	if Clock.phase == Clock.PHASE_DAY or Clock.phase == Clock.PHASE_DAWN:
		_place_sleepers()

func bed_position_for(id: String) -> Vector2:
	return _occupants.get(id, Vector2.ZERO)

func occupied_count() -> int:
	return _occupants.size()

func _on_dawn() -> void:
	_place_sleepers()

func _on_state_loaded() -> void:
	if Clock.phase == Clock.PHASE_DAY or Clock.phase == Clock.PHASE_DAWN:
		_place_sleepers()
	queue_redraw()

func _place_sleepers() -> void:
	_occupants.clear()
	for index in range(GameState.sleepers.size()):
		var id := String(GameState.sleepers[index])
		var bed := to_global(_bed_position(index))
		_occupants[id] = bed
		var person := _person_named(id)
		if person != null:
			person.global_position = bed
			if "velocity" in person:
				person.velocity = Vector2.ZERO
	queue_redraw()

func _bed_position(index: int) -> Vector2:
	var column := index % maxi(columns, 1)
	var row := int(index / maxi(columns, 1))
	return Vector2(float(column), float(row)) * spacing

func _person_named(id: String) -> Node2D:
	for group_name in ["persons", "townsfolk"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node.has_method("person_id") and String(node.person_id()) == id:
				return node as Node2D
	return null

func _draw() -> void:
	var rows := maxi(1, int(ceil(float(GameState.sleepers.size()) / maxi(columns, 1))))
	draw_rect(Rect2(-24, -34, maxf(columns, 1) * spacing.x + 20, rows * spacing.y + 44), Color("#182534"))
	draw_rect(Rect2(-18, -28, maxf(columns, 1) * spacing.x + 8, rows * spacing.y + 32), Color("#26354D"))
	for index in range(GameState.sleepers.size()):
		_draw_bed(index, String(GameState.sleepers[index]))

func _draw_bed(index: int, id: String) -> void:
	var bed := _bed_position(index)
	draw_rect(Rect2(bed + Vector2(-16, -8), Vector2(32, 22)), Color("#101826"))
	draw_rect(Rect2(bed + Vector2(-13, -11), Vector2(26, 19)), Color("#7CA5B8"))
	draw_rect(Rect2(bed + Vector2(-11, -9), Vector2(9, 6)), Color("#F4F7FA"))
	if _person_named(id) == null:
		draw_circle(bed + Vector2(0, -13), 5.0, Color("#F4F7FA"))
		draw_rect(Rect2(bed + Vector2(-7, -8), Vector2(14, 9)), Color("#5C7891"))
	draw_string(ThemeDB.fallback_font, bed + Vector2(-20, 28), id.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, 48, 9, Color("#F4F7FA"))
