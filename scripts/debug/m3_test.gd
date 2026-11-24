extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 3000
const BURST_SCENE := preload("res://scenes/lights/glint_burst.tscn")

var failures := 0
var testing := true
var runtime_left := RUNTIME_FRAMES
var step := 0
var step_frame := 0

var keeper: Node
var shadow: Node
var lantern: PointLight2D
var readout: Label

var value_before := 0.0
var max_before := 0.0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	keeper = $Maren
	shadow = keeper.get_node("ShadowComponent")
	lantern = keeper.get_node("Lantern")
	readout = $UI/Panel/Readout
	print("M3 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		runtime_left -= 1
		if runtime_left == 0:
			print("M3 RUNTIME CHECK COMPLETE")
			get_tree().quit(failures)
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M3 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _lantern_step()
		2: _wall_step()
		3: _exposure_step()
		4: _stage_step()
		5: _max_drop_step()
		6: _recovery_step()
		7: _glint_step()
		8: _finish_step()

func _structure_step() -> void:
	if step_frame < 2:
		return
	_expect(lantern != null and lantern.enabled,
		"PASS M3 lantern light exists and starts on", "FAIL M3 lantern missing or off")
	_expect(is_equal_approx(shadow.value, 1.0) and is_equal_approx(shadow.maximum, 1.0),
		"PASS M3 shadow starts full (100%)",
		"FAIL M3 shadow starts at %.2f / max %.2f" % [shadow.value, shadow.maximum])
	var wall := $Wall as StaticBody2D
	var obstacle_layer := int(Data.require_value("lighting.obstacle_layer"))
	_expect((wall.collision_layer & obstacle_layer) != 0,
		"PASS M3 wall is a daylight obstacle", "FAIL M3 wall not on the obstacle layer")
	_expect(keeper.glint_charges == int(Data.require_value("lighting.glint_charges")),
		"PASS M3 Glint starts with %d charges" % keeper.glint_charges,
		"FAIL M3 Glint starts with %d charges" % keeper.glint_charges)
	_advance(1)

func _lantern_step() -> void:
	if step_frame == 1:
		value_before = shadow.value
		keeper.set_lantern(false)
	elif step_frame == 20:
		keeper.set_lantern(true)
		_expect(is_equal_approx(shadow.value, value_before),
			"PASS M3 lantern has no gameplay effect on shadow",
			"FAIL M3 lantern changed shadow to %.3f" % shadow.value)
		_expect(lantern.enabled, "PASS M3 lantern toggles back on", "FAIL M3 lantern did not turn on")
		_advance(2)

func _wall_step() -> void:
	if step_frame == 1:
		_spawn_burst(Vector2(470, 320), 10.0)
	elif step_frame == 2:
		var burst = get_tree().get_first_node_in_group("daylight_fields")
		var clear: bool = burst.is_point_lit(Vector2(490, 320))
		var blocked: bool = burst.is_point_lit(Vector2(570, 320))
		var out_of_range: bool = burst.is_point_lit(Vector2(470, 520))
		_expect(clear, "PASS M3 daylight check sees a clear point", "FAIL M3 daylight check missed a clear point")
		_expect(not blocked, "PASS M3 Glint daylight is blocked by a wall", "FAIL M3 Glint daylight passed through a wall")
		_expect(not out_of_range, "PASS M3 daylight check respects range", "FAIL M3 daylight check ignored range")
		_clear_bursts()
		_advance(3)

func _exposure_step() -> void:
	if step_frame == 2:
		value_before = shadow.value
		_spawn_burst(keeper.global_position, 10.0)
	elif step_frame == 122:
		var drop: float = value_before - shadow.value
		var expected := float(Data.require_value("shadow.dawnglass_loss_rate")) * 2.0
		_expect(absf(drop - expected) < 0.02,
			"PASS M3 shadow drops while exposed (%.2f in 2 s)" % drop,
			"FAIL M3 exposure drop %.3f, expected %.3f" % [drop, expected])
		_expect(shadow.stage() == "normal",
			"PASS M3 high shadow is normal", "FAIL M3 stage is %s" % shadow.stage())
		_clear_bursts()
		_advance(4)

func _stage_step() -> void:
	if step_frame == 1:
		shadow.set_value(0.55)
		var flicker_a: float = shadow.visual_alpha(0.0)
		var flicker_b: float = shadow.visual_alpha(0.13)
		_expect(shadow.stage() == "flickering",
			"PASS M3 shadow flickers between 60% and 30%", "FAIL M3 stage at 55%% is %s" % shadow.stage())
		_expect(absf(flicker_a - flicker_b) > 0.01,
			"PASS M3 flickering shadow varies", "FAIL M3 flickering shadow is static")
		shadow.set_value(0.25)
		_expect(shadow.stage() == "faint",
			"PASS M3 shadow is faint below 30%", "FAIL M3 stage at 25%% is %s" % shadow.stage())
		var faint_alpha: float = shadow.visual_alpha(0.0)
		_expect(faint_alpha < 0.3, "PASS M3 faint shadow is dimmer", "FAIL M3 faint alpha %.2f" % faint_alpha)
	elif step_frame == 20:
		shadow.maximum = 1.0
		shadow.set_value(1.0)
		_advance(5)

func _max_drop_step() -> void:
	if step_frame == 1:
		max_before = shadow.maximum
		shadow.set_value(0.32)
		_spawn_burst(keeper.global_position, 20.0)
	elif step_frame == 60:
		var dropped: bool = is_equal_approx(shadow.maximum, max_before - 0.1)
		_expect(dropped and shadow.value < 0.3,
			"PASS M3 falling below 30%% lowers max to %d%%" % roundi(shadow.maximum * 100.0),
			"FAIL M3 max %.2f, value %.2f" % [shadow.maximum, shadow.value])
	elif step_frame == 130:
		_expect(is_equal_approx(shadow.maximum, max_before - 0.1),
			"PASS M3 max drops only once per crossing",
			"FAIL M3 max dropped again to %.2f" % shadow.maximum)
		_clear_bursts()
		Clock.phase = Clock.PHASE_DAY
	elif step_frame == 560:
		_expect(shadow.value > 0.3,
			"PASS M3 recovery raises shadow above 30%% (%.2f)" % shadow.value,
			"FAIL M3 recovery stalled at %.2f" % shadow.value)
		Clock.phase = Clock.PHASE_NIGHT
		shadow.set_value(0.32)
		_spawn_burst(keeper.global_position, 10.0)
	elif step_frame == 620:
		_expect(is_equal_approx(shadow.maximum, max_before - 0.2),
			"PASS M3 second crossing drops max to %d%%" % roundi(shadow.maximum * 100.0),
			"FAIL M3 second drop max %.2f" % shadow.maximum)
		_clear_bursts()
		_advance(6)

func _recovery_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DAY
		shadow.maximum = 0.8
		shadow.set_value(0.5)
		value_before = 0.5
	elif step_frame == 121:
		var rise: float = shadow.value - value_before
		var expected := float(Data.require_value("shadow.sunlight_recovery_rate")) * 2.0
		_expect(absf(rise - expected) < 0.02,
			"PASS M3 shadow recovers in daylight (%.2f in 2 s)" % rise,
			"FAIL M3 recovery %.3f, expected %.3f" % [rise, expected])
		shadow.set_value(0.79)
	elif step_frame == 241:
		_expect(is_equal_approx(shadow.value, shadow.maximum),
			"PASS M3 recovery stops at the maximum (%d%%)" % roundi(shadow.maximum * 100.0),
			"FAIL M3 recovery %.2f against max %.2f" % [shadow.value, shadow.maximum])
		Clock.phase = Clock.PHASE_NIGHT
		_advance(7)

func _glint_step() -> void:
	if step_frame == 1:
		value_before = shadow.value
	elif step_frame == 2:
		var charges_before: int = keeper.glint_charges
		var fired: bool = keeper.fire_glint()
		_expect(fired and keeper.glint_charges == charges_before - 1,
			"PASS M3 Glint spends a charge (%d left)" % keeper.glint_charges,
			"FAIL M3 Glint charge not spent")
	elif step_frame == 3:
		var cost: float = value_before - shadow.value
		var expected := float(Data.require_value("shadow.glint_cost"))
		_expect(absf(cost - expected) < 0.01,
			"PASS M3 Glint costs %.2f shadow" % cost,
			"FAIL M3 Glint cost %.3f, expected %.3f" % [cost, expected])
		while keeper.glint_charges > 0:
			keeper.fire_glint()
		_expect(keeper.glint_charges == 0,
			"PASS M3 Glint charges run out", "FAIL M3 Glint charges %d" % keeper.glint_charges)
		_expect(not keeper.fire_glint(),
			"PASS M3 Glint refuses to fire at 0 charges", "FAIL M3 Glint fired with no charges")
	elif step_frame == 10:
		_clear_bursts()
		_advance(8)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_expect(readout.text.contains("Shadow") and readout.text.contains("%") and readout.text.contains("Glint"),
		"PASS M3 readout shows shadow, max and Glint charges",
		"FAIL M3 readout: %s" % readout.text)
	_finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M3 TESTS PASS")
	else:
		print("M3 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M3 RUNTIME CHECK START")

func _spawn_burst(at: Vector2, duration: float) -> Node2D:
	var burst := BURST_SCENE.instantiate()
	add_child(burst)
	burst.global_position = at
	burst.configure(
		float(Data.require_value("lighting.glint_radius")),
		duration,
		int(Data.require_value("lighting.obstacle_layer"))
	)
	return burst

func _clear_bursts() -> void:
	for field in get_tree().get_nodes_in_group("daylight_fields"):
		field.queue_free()

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
