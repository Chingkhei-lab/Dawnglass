extends "res://scripts/creatures/creature_base.gd"

const STATE_HIDDEN := "hidden"
const STATE_RUSH := "rush"

var state := STATE_HIDDEN
var target: Node = null

var _trigger_radius := 0.0
var _lantern_range := 0.0
var _rush_speed := 0.0

func _ready() -> void:
	super._ready()
	_trigger_radius = float(Data.require_value("creatures.lurker_trigger_radius"))
	_lantern_range = float(Data.require_value("creatures.lurker_lantern_notice_range"))
	_rush_speed = float(Data.require_value("creatures.lurker_rush_speed"))

func _behave(delta: float) -> void:
	if state == STATE_HIDDEN:
		target = _notice()
		if target != null:
			state = STATE_RUSH
		return
	if target == null or not is_instance_valid(target):
		_reset()
		return
	if target.has_method("is_takeable") and not target.is_takeable():
		_reset()
		return
	_move_toward(target.global_position, _rush_speed, delta)

func _notice() -> Node:
	var person := _nearest_person(_trigger_radius)
	if person != null:
		return person
	var holder: Node = null
	var best := _lantern_range
	for candidate in get_tree().get_nodes_in_group("persons"):
		if not candidate.has_method("is_lantern_on") or not candidate.is_lantern_on():
			continue
		if not candidate.is_takeable():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= best:
			best = distance
			holder = candidate
	return holder

func _reset() -> void:
	state = STATE_HIDDEN
	target = null

func _draw_silhouette() -> void:
	draw_colored_polygon(_ellipse(Vector2(0, 0), Vector2(12, 4)), Color(0.035, 0.045, 0.07, 1))
	draw_colored_polygon(_ellipse(Vector2(0, -7), Vector2(10, 7)), Color(0.05, 0.07, 0.1, 1))
