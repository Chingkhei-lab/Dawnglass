extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 3000
const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")

var failures := 0
var testing := true
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var runtime_frame := 0

var beam: Node2D
var keeper: Node
var shadow: Node
var readout: Label

var prev_speed := 0.0
var max_speed := 0.0
var first_delta := -1.0
var angle_at_start := 0.0

var charge_before := 0.0
var shadow_before := 0.0

var auto_min := 999.0
var auto_max := -999.0
var auto_flips := 0
var auto_last_sign := 0
var gap_lit := false
var far_walker: Node = null
var pulse_fired := false
var spawn_index := 0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	Clock.dawnglass_charge = 0.5
	beam = $Lighthouse/Beam
	beam.input_enabled = false
	keeper = $Maren
	shadow = keeper.get_node("ShadowComponent")
	readout = $UI/Panel/Readout
	print("M5 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		_runtime_tick()
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M5 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _turn_step()
		2: _occlusion_step()
		3: _drain_step()
		4: _sweep_step()
		5: _pulse_step()
		6: _readout_step()
		7: _finish_step()

func _structure_step() -> void:
	if step_frame < 3:
		return
	_expect(beam.is_in_group("daylight_fields") and beam.has_method("is_point_lit"),
		"PASS M5 beam is a daylight field", "FAIL M5 beam is not a daylight field")
	_expect($Lighthouse/LampRoom is Area2D,
		"PASS M5 lamp room exists", "FAIL M5 lamp room missing")
	_expect(beam.operator == keeper,
		"PASS M5 keeper in the lamp room operates the beam", "FAIL M5 beam has no operator")
	_expect(beam.is_beam_on(),
		"PASS M5 beam lights while staffed and charged", "FAIL M5 beam is off with an operator and charge")
	_expect(InputMap.has_action("focus"),
		"PASS M5 focus action is registered", "FAIL M5 focus action missing")
	_expect(beam.manual_control,
		"PASS M5 beam starts under player control", "FAIL M5 beam starts in auto mode")
	_advance(1)

func _turn_step() -> void:
	if step_frame == 1:
		beam.input_enabled = false
		beam.manual_control = true
		beam.angular_velocity = 0.0
		beam.set_target_angle(deg_to_rad(90.0))
		prev_speed = absf(beam.angular_velocity)
		max_speed = prev_speed
		first_delta = -1.0
		angle_at_start = beam.angle
		return
	var speed := absf(beam.angular_velocity)
	if step_frame == 2:
		first_delta = rad_to_deg(speed - prev_speed)
		var turned := absf(rad_to_deg(beam.angle - angle_at_start))
		_expect(first_delta > 2.5 and first_delta < 5.5,
			"PASS M5 turn acceleration %.1f deg/s^2" % [first_delta * 60.0],
			"FAIL M5 first-frame turn delta %.2f deg/s" % first_delta)
		_expect(turned < 2.0,
			"PASS M5 beam does not snap (%.2f deg in one frame)" % turned,
			"FAIL M5 beam snapped %.2f deg in one frame" % turned)
	prev_speed = speed
	max_speed = maxf(max_speed, speed)
	if step_frame == 120:
		var settled := absf(rad_to_deg(beam.angle) - 90.0)
		_expect(settled < 2.0,
			"PASS M5 beam settles on the aim angle (%.2f deg off)" % settled,
			"FAIL M5 beam is %.2f deg off target" % settled)
		var top_speed := rad_to_deg(max_speed)
		_expect(absf(top_speed - 90.0) < 3.0,
			"PASS M5 turn speed %.1f deg/s matches tuning" % top_speed,
			"FAIL M5 turn speed %.1f deg/s, expected 90" % top_speed)
		_advance(2)

func _occlusion_step() -> void:
	if step_frame == 1:
		beam.set_target_angle(0.0)
		return
	if step_frame != 160:
		return
	_expect(absf(rad_to_deg(beam.angle)) < 2.0,
		"PASS M5 beam returned to the test angle", "FAIL M5 beam did not return (%.1f deg)" % rad_to_deg(beam.angle))
	_expect(beam.is_point_lit(Vector2(300, 200)),
		"PASS M5 beam lights a clear point", "FAIL M5 clear point is dark")
	_expect(not beam.is_point_lit(Vector2(440, 200)),
		"PASS M5 rock blocks the beam", "FAIL M5 beam passes through the rock")
	var range_point: Vector2 = Vector2(160, 200) + Vector2.RIGHT.rotated(deg_to_rad(7.0)) * 330.0
	_expect(not beam.is_point_lit(range_point),
		"PASS M5 beam respects its range", "FAIL M5 beam lights beyond its range")
	var cone_point: Vector2 = Vector2(160, 200) + Vector2.RIGHT.rotated(deg_to_rad(20.0)) * 140.0
	_expect(not beam.is_point_lit(cone_point),
		"PASS M5 beam respects its cone", "FAIL M5 beam lights outside its cone")
	_advance(3)

func _drain_step() -> void:
	if step_frame == 1:
		Clock.dawnglass_charge = 0.5
		shadow.value = 1.0
		charge_before = Clock.dawnglass_charge
		shadow_before = shadow.value
		_expect(beam.is_beam_on(),
			"PASS M5 beam on for the drain check", "FAIL M5 beam off for the drain check")
		return
	if step_frame == 121:
		var charge_drop: float = charge_before - Clock.dawnglass_charge
		var shadow_drop: float = shadow_before - shadow.value
		_expect(absf(charge_drop - 0.005) < 0.002,
			"PASS M5 beam uses 0.005 Dawnglass in 2 s (%.4f)" % charge_drop,
			"FAIL M5 Dawnglass use %.4f, expected 0.005" % charge_drop)
		_expect(absf(shadow_drop - 0.02) < 0.004,
			"PASS M5 operator loses 0.02 shadow in 2 s (%.3f)" % shadow_drop,
			"FAIL M5 operator loss %.3f, expected 0.02" % shadow_drop)
		return
	if step_frame == 122:
		Clock.dawnglass_charge = 0.0
	elif step_frame == 127:
		_expect(not beam.is_beam_on(),
			"PASS M5 beam stops when stored Dawnglass is empty", "FAIL M5 beam ran with no Dawnglass")
		_expect(Clock.dawnglass_charge == 0.0,
			"PASS M5 Dawnglass never goes negative", "FAIL M5 Dawnglass is %.3f" % Clock.dawnglass_charge)
	elif step_frame == 128:
		Clock.dawnglass_charge = 0.5
	elif step_frame == 131:
		_expect(beam.is_beam_on(),
			"PASS M5 beam resumes with stored Dawnglass", "FAIL M5 beam did not resume")
		_advance(4)

func _sweep_step() -> void:
	if step_frame == 1:
		beam.enter_auto()
		auto_min = rad_to_deg(beam.angle)
		auto_max = auto_min
		auto_flips = 0
		auto_last_sign = 0
		gap_lit = false
		return
	var angle_deg := rad_to_deg(beam.angle)
	auto_min = minf(auto_min, angle_deg)
	auto_max = maxf(auto_max, angle_deg)
	var sign := signi(int(signf(beam.angular_velocity) * 1000.0))
	if sign != 0:
		if auto_last_sign != 0 and sign != auto_last_sign:
			auto_flips += 1
		auto_last_sign = sign
	if beam.is_point_lit(Vector2(300, 200)):
		gap_lit = true
	if step_frame == 601:
		_expect(auto_min > 28.0 and auto_max < 152.0,
			"PASS M5 auto sweep stays inside %.0f-%.0f deg" % [auto_min, auto_max],
			"FAIL M5 sweep range %.1f-%.1f" % [auto_min, auto_max])
		_expect(absf(auto_max - 150.0) < 2.0 and absf(auto_min - 30.0) < 2.0,
			"PASS M5 auto sweep reaches both ends %.0f/%.0f" % [auto_min, auto_max],
			"FAIL M5 sweep did not reach its ends (%.1f/%.1f)" % [auto_min, auto_max])
		_expect(auto_flips == 1,
			"PASS M5 auto sweep reverses once per leg", "FAIL M5 sweep reverses %d times" % auto_flips)
		_expect(not gap_lit,
			"PASS M5 auto sweep leaves the intended gap", "FAIL M5 sweep lit the gap sector")
		_advance(5)

func _pulse_step() -> void:
	if step_frame == 1:
		Clock.dawnglass_charge = 0.8
		shadow.value = 1.0
		_spawn(WALKER_SCENE, Vector2(10, 200))
		_spawn(WALKER_SCENE, Vector2(-90, 200))
		far_walker = _spawn(WALKER_SCENE, Vector2(660, 200))
		charge_before = Clock.dawnglass_charge
		shadow_before = shadow.value
		pulse_fired = beam.fire_dawn_pulse()
		_expect(pulse_fired,
			"PASS M5 Dawn Pulse fires from the lamp room", "FAIL M5 Dawn Pulse did not fire")
		_expect(absf((charge_before - Clock.dawnglass_charge) - 0.5) < 0.01,
			"PASS M5 Dawn Pulse spends 0.50 Dawnglass",
			"FAIL M5 pulse spent %.2f Dawnglass" % (charge_before - Clock.dawnglass_charge))
		_expect(absf((shadow_before - shadow.value) - 0.2) < 0.01,
			"PASS M5 Dawn Pulse costs the operator 0.20 shadow",
			"FAIL M5 pulse cost %.2f shadow" % (shadow_before - shadow.value))
		return
	if step_frame == 80:
		_expect(_creature_count() == 1 and is_instance_valid(far_walker),
			"PASS M5 Dawn Pulse destroys creatures in its ring",
			"FAIL M5 %d creatures left after the pulse" % _creature_count())
		_expect(_field_count() == 1,
			"PASS M5 Dawn Pulse clears its field", "FAIL M5 %d daylight fields remain" % _field_count())
		_clear_creatures()
		Clock.dawnglass_charge = 0.5
		_advance(6)

func _readout_step() -> void:
	if step_frame < 3:
		return
	_expect(readout.text.contains("Beam") and readout.text.contains("Dawnglass"),
		"PASS M5 readout shows beam, mode and Dawnglass", "FAIL M5 readout: %s" % readout.text)
	_advance(7)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M5 TESTS PASS")
	else:
		print("M5 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M5 RUNTIME CHECK START")
	beam.enter_auto()
	Clock.dawnglass_charge = 1.0
	shadow.value = 1.0

func _runtime_tick() -> void:
	runtime_left -= 1
	runtime_frame += 1
	if runtime_frame % 120 == 0 and _creature_count() < 8:
		var sector := 30.0 + float((spawn_index * 37) % 120)
		spawn_index += 1
		var offset := Vector2.RIGHT.rotated(deg_to_rad(sector)) * 240.0
		_spawn(WALKER_SCENE, beam.global_position + offset)
	if runtime_left <= 0:
		print("M5 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var creature := scene.instantiate()
	add_child(creature)
	creature.global_position = at
	return creature

func _clear_creatures() -> void:
	for creature in get_tree().get_nodes_in_group("creatures"):
		creature.queue_free()

func _creature_count() -> int:
	return get_tree().get_nodes_in_group("creatures").size()

func _field_count() -> int:
	return get_tree().get_nodes_in_group("daylight_fields").size()

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
