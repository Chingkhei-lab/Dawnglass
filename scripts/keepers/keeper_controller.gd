extends CharacterBody2D

signal interacted(text: String)
signal glint_fired(charges_left: int)

const GLINT_SCENE := preload("res://scenes/lights/glint_burst.tscn")
const KEY_BINDINGS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"interact": KEY_E,
	"lantern": KEY_F,
	"glint": KEY_Q,
}
const AXIS_BINDINGS := [
	["move_left", JOY_AXIS_LEFT_X, -1.0],
	["move_right", JOY_AXIS_LEFT_X, 1.0],
	["move_up", JOY_AXIS_LEFT_Y, -1.0],
	["move_down", JOY_AXIS_LEFT_Y, 1.0],
]
const BUTTON_BINDINGS := [
	["interact", JOY_BUTTON_A],
	["lantern", JOY_BUTTON_B],
	["glint", JOY_BUTTON_X],
]

@export var speed_path := "movement.keeper_speed"
@onready var interaction_probe: Area2D = $InteractionProbe

var glint_charges := 0
var taken := false
var _shadow: Node = null
var _lantern: PointLight2D = null
var _elapsed := 0.0

func _ready() -> void:
	add_to_group("persons")
	_bind_input()
	_shadow = get_node_or_null("ShadowComponent")
	_lantern = get_node_or_null("Lantern") as PointLight2D
	glint_charges = int(Data.require_value("lighting.glint_charges"))
	_apply_lantern_radius()

func _physics_process(delta: float) -> void:
	if taken:
		queue_redraw()
		return
	_elapsed += delta
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * float(Data.require_value(speed_path))
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		try_interact()
	if Input.is_action_just_pressed("lantern"):
		set_lantern(not is_lantern_on())
	if Input.is_action_just_pressed("glint"):
		fire_glint()
	_update_shadow(delta)
	queue_redraw()

func try_interact() -> bool:
	var target := _nearest_interactable()
	if target == null:
		return false
	interacted.emit(target.interact())
	return true

func set_lantern(enabled: bool) -> void:
	if _lantern == null:
		return
	_lantern.enabled = enabled

func is_lantern_on() -> bool:
	return _lantern != null and _lantern.enabled

func is_takeable() -> bool:
	return not taken

func take_shadow() -> void:
	if taken:
		return
	taken = true
	GameState.mark_sleeper(name)
	Events.person_taken.emit()

func shadow_lean() -> Vector2:
	var lean_range := float(Data.require_value("creatures.lean_range"))
	var nearest: Node2D = null
	var nearest_distance := lean_range
	for node in get_tree().get_nodes_in_group("creatures"):
		var creature := node as Node2D
		if creature == null:
			continue
		var distance := global_position.distance_to(creature.global_position)
		if distance <= nearest_distance:
			nearest = creature
			nearest_distance = distance
	if nearest == null:
		return Vector2.ZERO
	var direction := (nearest.global_position - global_position).normalized()
	var strength := 1.0 - nearest_distance / maxf(lean_range, 0.001)
	return direction * float(Data.require_value("creatures.lean_max")) * strength

func fire_glint() -> bool:
	if glint_charges <= 0:
		return false
	glint_charges -= 1
	var burst := GLINT_SCENE.instantiate()
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	burst.configure(
		float(Data.require_value("lighting.glint_radius")),
		float(Data.require_value("lighting.glint_duration")),
		int(Data.require_value("lighting.obstacle_layer"))
	)
	if _shadow != null:
		_shadow.apply_cost(float(Data.require_value("shadow.glint_cost")))
	glint_fired.emit(glint_charges)
	return true

func _update_shadow(delta: float) -> void:
	if _shadow == null:
		return
	if _is_exposed():
		_shadow.apply_exposure(delta)
	elif Clock.phase == Clock.PHASE_DAY:
		_shadow.recover(delta)

func _is_exposed() -> bool:
	for field in get_tree().get_nodes_in_group("daylight_fields"):
		if field.has_method("is_point_lit") and field.is_point_lit(global_position):
			return true
	return false

func _apply_lantern_radius() -> void:
	if _lantern == null:
		return
	var radius := float(Data.require_value("lighting.lantern_radius"))
	if _lantern.texture != null:
		_lantern.texture_scale = radius * 2.0 / float(_lantern.texture.get_width())

func _nearest_interactable() -> Node:
	var best: Node = null
	var best_distance := INF
	for area in interaction_probe.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best = area
			best_distance = distance
	return best

func _bind_input() -> void:
	for action in KEY_BINDINGS:
		_ensure_action(action)
		_add_event_once(action, _key_event(KEY_BINDINGS[action]))
	for binding in AXIS_BINDINGS:
		_ensure_action(binding[0])
		_add_event_once(binding[0], _axis_event(binding[1], binding[2]))
	for binding in BUTTON_BINDINGS:
		_ensure_action(binding[0])
		_add_event_once(binding[0], _button_event(binding[1]))

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _add_event_once(action: String, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == event.as_text():
			return
	InputMap.action_add_event(action, event)

func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event

func _axis_event(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event

func _button_event(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event

func _draw() -> void:
	var shadow_alpha := 0.8
	if _shadow != null:
		shadow_alpha = _shadow.visual_alpha(_elapsed)
	var lean := shadow_lean()
	draw_colored_polygon(
		_ellipse(lean, Vector2(9.0 + lean.length() * 0.25, 3.5)),
		Color(0.078, 0.106, 0.161, shadow_alpha)
	)
	draw_rect(Rect2(-7, -18, 14, 18), Color("#7CA5B8"))
	draw_circle(Vector2(0, -22), 7.0, Color("#F4F7FA"))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
