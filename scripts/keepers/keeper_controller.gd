extends CharacterBody2D

signal interacted(text: String)

const KEY_BINDINGS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"interact": KEY_E,
}
const AXIS_BINDINGS := [
	["move_left", JOY_AXIS_LEFT_X, -1.0],
	["move_right", JOY_AXIS_LEFT_X, 1.0],
	["move_up", JOY_AXIS_LEFT_Y, -1.0],
	["move_down", JOY_AXIS_LEFT_Y, 1.0],
]
const BUTTON_BINDINGS := [
	["interact", JOY_BUTTON_A],
]

@export var speed_path := "movement.keeper_speed"
@onready var interaction_probe: Area2D = $InteractionProbe

func _ready() -> void:
	_bind_input()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * float(Data.require_value(speed_path))
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		try_interact()

func try_interact() -> bool:
	var target := _nearest_interactable()
	if target == null:
		return false
	interacted.emit(target.interact())
	return true

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
	draw_colored_polygon(_ellipse(Vector2(0, 0), Vector2(9, 3.5)), Color("#141B29"))
	draw_rect(Rect2(-7, -18, 14, 18), Color("#7CA5B8"))
	draw_circle(Vector2(0, -22), 7.0, Color("#F4F7FA"))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
