extends Node2D

var contact_enabled := true

var _contact_radius := 0.0

func _ready() -> void:
	add_to_group("creatures")
	_contact_radius = float(Data.require_value("creatures.contact_radius"))

func _physics_process(delta: float) -> void:
	if _in_daylight():
		Events.creature_destroyed.emit()
		queue_free()
		return
	_behave(delta)
	_check_contact()

func _behave(_delta: float) -> void:
	pass

func _move_toward(point: Vector2, speed: float, delta: float) -> void:
	var offset := point - global_position
	if offset.length_squared() < 0.0001:
		return
	global_position += offset.normalized() * speed * delta

func _nearest_person(max_distance := INF) -> Node:
	var best: Node = null
	var best_distance := max_distance
	for person in get_tree().get_nodes_in_group("persons"):
		if not person.has_method("is_takeable") or not person.is_takeable():
			continue
		var distance := global_position.distance_to(person.global_position)
		if distance < best_distance:
			best = person
			best_distance = distance
	return best

func _in_daylight() -> bool:
	for field in get_tree().get_nodes_in_group("daylight_fields"):
		if field.has_method("is_point_lit") and field.is_point_lit(global_position):
			return true
	return false

func _check_contact() -> void:
	if not contact_enabled:
		return
	for person in get_tree().get_nodes_in_group("persons"):
		if person.has_method("is_takeable") and not person.is_takeable():
			continue
		if global_position.distance_to(person.global_position) > _contact_radius:
			continue
		if person.has_method("take_shadow"):
			person.take_shadow()
		queue_free()
		return

func _draw() -> void:
	_draw_silhouette()

func _draw_silhouette() -> void:
	draw_colored_polygon(_ellipse(Vector2(0, 0), Vector2(8, 3)), Color(0.04, 0.05, 0.08, 1))
	draw_rect(Rect2(-6, -16, 12, 16), Color(0.06, 0.08, 0.12, 1))
	draw_circle(Vector2(0, -19), 6.0, Color(0.06, 0.08, 0.12, 1))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
