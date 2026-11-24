extends Node2D

const DaylightCheck := preload("res://scripts/world/daylight_check.gd")
const PULSE_SCENE := preload("res://scenes/lights/dawn_pulse.tscn")

@export var lamp_room_path: NodePath

var angle := 0.0
var angular_velocity := 0.0
var manual_control := true
var input_enabled := true
var focused := false
var operator: Node = null

var _target_angle := 0.0
var _sweep_to_max := true
var _pause_left := 0.0
var _lamp_room: Area2D = null
var _last_operator: Node = null
var _last_controlled := true

func _ready() -> void:
	add_to_group("daylight_fields")
	_bind_focus()
	_lamp_room = get_node_or_null(lamp_room_path) as Area2D

func _physics_process(delta: float) -> void:
	_refresh_operator()
	_sync_operator_control()
	if input_enabled:
		focused = Input.is_action_pressed("focus")
	if not is_beam_on():
		angular_velocity = 0.0
		queue_redraw()
		return
	if manual_control:
		var target := _input_target() if input_enabled else _target_angle
		_steer_to(target, delta)
	else:
		_steer_auto(delta)
	_consume(delta)
	queue_redraw()

func is_beam_on() -> bool:
	if operator == null or Clock.dawnglass_charge <= 0.0:
		return false
	return Clock.phase == Clock.PHASE_DUSK or Clock.phase == Clock.PHASE_NIGHT

func set_target_angle(target: float) -> void:
	_target_angle = wrapf(target, -PI, PI)

func enter_auto() -> void:
	manual_control = false
	angle = deg_to_rad(float(Data.require_value("beam.sweep_min_deg")))
	angular_velocity = 0.0
	_sweep_to_max = true
	_pause_left = 0.0

func fire_dawn_pulse() -> bool:
	if operator == null:
		return false
	var charge_cost := float(Data.require_value("beam.pulse_dawnglass_cost"))
	if Clock.dawnglass_charge < charge_cost:
		return false
	Clock.dawnglass_charge -= charge_cost
	var shadow := operator.get_node_or_null("ShadowComponent")
	if shadow != null:
		shadow.apply_cost(float(Data.require_value("beam.pulse_shadow_cost")))
	var pulse := PULSE_SCENE.instantiate()
	get_tree().current_scene.add_child(pulse)
	pulse.global_position = global_position
	pulse.configure(
		float(Data.require_value("beam.pulse_radius")),
		float(Data.require_value("beam.pulse_duration")),
		float(Data.require_value("beam.pulse_band")),
		int(Data.require_value("lighting.obstacle_layer"))
	)
	return true

func is_point_lit(point: Vector2) -> bool:
	if not is_beam_on():
		return false
	var offset := point - global_position
	if offset.length() <= float(Data.require_value("beam.lamp_room_radius")):
		return false
	return DaylightCheck.is_lit(
		get_world_2d().direct_space_state,
		point,
		global_position,
		float(Data.require_value("beam.range")),
		Vector2.RIGHT.rotated(angle),
		_half_angle_deg(),
		int(Data.require_value("lighting.obstacle_layer"))
	)

func _half_angle_deg() -> float:
	if focused:
		return float(Data.require_value("beam.focus_half_angle_deg"))
	return float(Data.require_value("beam.half_angle_deg"))

func _steer_to(target: float, delta: float) -> void:
	var max_speed := deg_to_rad(float(Data.require_value("beam.turn_speed_deg")))
	var accel := deg_to_rad(float(Data.require_value("beam.turn_accel_deg")))
	var diff := wrapf(target - angle, -PI, PI)
	var desired := clampf(diff / maxf(delta, 0.0001), -max_speed, max_speed)
	var braking := sqrt(2.0 * accel * absf(diff))
	desired = clampf(desired, -braking, braking)
	angular_velocity = move_toward(angular_velocity, desired, accel * delta)
	angular_velocity = clampf(angular_velocity, -max_speed, max_speed)
	angle = wrapf(angle + angular_velocity * delta, -PI, PI)

func _steer_auto(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		angular_velocity = 0.0
		return
	var speed := deg_to_rad(float(Data.require_value("beam.sweep_speed_deg")))
	var limit := float(Data.require_value("beam.sweep_max_deg")) if _sweep_to_max else float(Data.require_value("beam.sweep_min_deg"))
	var target := deg_to_rad(limit)
	var diff := wrapf(target - angle, -PI, PI)
	if absf(diff) <= speed * delta:
		angle = target
		angular_velocity = 0.0
		_pause_left = float(Data.require_value("beam.sweep_pause"))
		_sweep_to_max = not _sweep_to_max
		return
	angular_velocity = signf(diff) * speed
	angle = wrapf(angle + angular_velocity * delta, -PI, PI)

func _input_target() -> float:
	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if stick.length() > 0.25:
		return stick.angle()
	var mouse := get_global_mouse_position() - global_position
	if mouse.length() > 8.0:
		return mouse.angle()
	return _target_angle

func _consume(delta: float) -> void:
	var multiplier := float(Data.require_value("beam.focus_drain_multiplier")) if focused else 1.0
	var charge_rate := float(Data.require_value("beam.dawnglass_per_second"))
	Clock.dawnglass_charge = maxf(0.0, Clock.dawnglass_charge - charge_rate * multiplier * delta)
	var shadow := operator.get_node_or_null("ShadowComponent")
	if shadow != null:
		shadow.apply_cost(float(Data.require_value("beam.shadow_per_second")) * multiplier * delta)

func _refresh_operator() -> void:
	operator = null
	if _lamp_room == null:
		return
	for body in _lamp_room.get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("persons"):
			operator = body
			return

func _sync_operator_control() -> void:
	if operator == null:
		return
	if operator != _last_operator or operator.controlled != _last_controlled:
		_last_operator = operator
		_last_controlled = operator.controlled
		manual_control = operator.controlled

func _bind_focus() -> void:
	if not InputMap.has_action("focus"):
		InputMap.add_action("focus")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SHIFT
	InputMap.action_add_event("focus", key)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("focus", mouse)

func _draw() -> void:
	if not is_beam_on():
		return
	var beam_range := float(Data.require_value("beam.range"))
	var half := deg_to_rad(_half_angle_deg())
	var color := Color(1.0, 0.95, 0.75, 0.32 if focused else 0.18)
	draw_colored_polygon(PackedVector2Array([
		Vector2.ZERO,
		Vector2.RIGHT.rotated(angle - half) * beam_range,
		Vector2.RIGHT.rotated(angle + half) * beam_range,
	]), color)
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.95, 0.7, 0.9))
