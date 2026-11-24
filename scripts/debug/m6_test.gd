extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 3000
const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")
const BURST_SCENE := preload("res://scenes/lights/glint_burst.tscn")

var failures := 0
var testing := true
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var runtime_frame := 0

var maren: Node
var ivo: Node
var switcher: Node
var camera: Camera2D
var beam: Node
var readout: Label
var maren_shadow: Node
var ivo_shadow: Node

var beam_angle_start := 0.0
var sweep_moved := false
var camera_start := 0.0
var ivo_start_x := 0.0
var ivo_guard := Vector2.ZERO
var maren_start_x := 0.0
var spawn_index := 0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	Clock.dawnglass_charge = 0.5
	maren = $Maren
	ivo = $Ivo
	switcher = $KeeperSwitch
	camera = $Camera2D
	beam = $Lighthouse/Beam
	readout = $UI/Panel/Readout
	maren_shadow = maren.get_node("ShadowComponent")
	ivo_shadow = ivo.get_node("ShadowComponent")
	camera.global_position = maren.global_position
	print("M6 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		_runtime_tick()
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M6 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _switch_step()
		2: _mid_movement_step()
		3: _shadow_step()
		4: _lamp_room_step()
		5: _readout_step()
		6: _finish_step()

func _structure_step() -> void:
	if step_frame < 3:
		return
	_expect(get_tree().get_nodes_in_group("keepers").size() == 2,
		"PASS M6 two keepers are registered", "FAIL M6 keeper count is %d" % get_tree().get_nodes_in_group("keepers").size())
	_expect(maren.controlled and not ivo.controlled,
		"PASS M6 Maren starts controlled", "FAIL M6 wrong keeper starts controlled")
	_expect(switcher.active_keeper() == maren and camera.target_override == maren,
		"PASS M6 camera follows the active keeper", "FAIL M6 camera target is wrong")
	_expect(beam.operator == maren and beam.manual_control,
		"PASS M6 controlled keeper in the lamp room drives the beam",
		"FAIL M6 beam staffing is wrong")
	_expect(InputMap.has_action("switch_keeper"),
		"PASS M6 switch action is registered", "FAIL M6 switch action missing")
	_advance(1)

func _switch_step() -> void:
	if step_frame == 1:
		camera_start = camera.global_position.distance_to(ivo.global_position)
		switcher.switch_next()
		beam_angle_start = beam.angle
		sweep_moved = false
		return
	if step_frame == 2:
		_expect(not maren.controlled and ivo.controlled,
			"PASS M6 one button switches control", "FAIL M6 control did not switch")
		_expect(switcher.active_keeper() == ivo and camera.target_override == ivo,
			"PASS M6 camera retargets to the new keeper", "FAIL M6 camera did not retarget")
		_expect(beam.operator == maren and not beam.manual_control,
			"PASS M6 keeper left in the lamp room switches the beam to auto",
			"FAIL M6 beam did not enter auto mode")
	if absf(beam.angular_velocity) > 0.1:
		sweep_moved = true
	if step_frame == 90:
		var swept := absf(rad_to_deg(beam.angle - beam_angle_start))
		_expect(sweep_moved and swept > 2.0,
			"PASS M6 left keeper keeps sweeping (%.1f deg)" % swept,
			"FAIL M6 beam did not sweep (%.2f deg)" % swept)
		var distance := camera.global_position.distance_to(ivo.global_position)
		_expect(distance < 3.0 and distance < camera_start,
			"PASS M6 camera glides to the new keeper (%.1f -> %.1f px)" % [camera_start, distance],
			"FAIL M6 camera at %.1f px from the new keeper" % distance)
		_expect(maren.position.distance_to(Vector2(160, 210)) < 0.5,
			"PASS M6 left keeper stays put while uncontrolled",
			"FAIL M6 left keeper drifted")
		_advance(2)

func _mid_movement_step() -> void:
	if step_frame == 1:
		Input.action_press("move_right")
		ivo_start_x = ivo.position.x
	elif step_frame == 31:
		var moved: float = ivo.position.x - ivo_start_x
		_expect(moved > 20.0,
			"PASS M6 controlled keeper moves (%.1f px)" % moved, "FAIL M6 keeper moved %.1f px" % moved)
		ivo_guard = ivo.position
		switcher.switch_next()
		maren_start_x = maren.position.x
	elif step_frame == 61:
		_expect(ivo.position.distance_to(ivo_guard) < 0.5,
			"PASS M6 switching mid-movement stops the old keeper",
			"FAIL M6 old keeper kept moving %.1f px" % ivo.position.distance_to(ivo_guard))
		_expect(maren.position.x - maren_start_x > 20.0,
			"PASS M6 new keeper takes over mid-movement",
			"FAIL M6 new keeper did not move")
		_expect(maren.controlled,
			"PASS M6 control moved to Maren", "FAIL M6 control is not on Maren")
		Input.action_release("move_right")
		_advance(3)

func _shadow_step() -> void:
	if step_frame == 1:
		maren.position = Vector2(600, 400)
		ivo.position = Vector2(620, 400)
		maren_shadow.value = 1.0
		ivo_shadow.value = 1.0
		_spawn_burst(Vector2(610, 430), 3.0)
		return
	if step_frame == 121:
		_expect(absf(float(maren_shadow.value) - 0.9) < 0.03,
			"PASS M6 controlled keeper shadow updates (%.2f)" % maren_shadow.value,
			"FAIL M6 controlled shadow %.2f, expected 0.90" % maren_shadow.value)
		_expect(absf(float(ivo_shadow.value) - 0.9) < 0.03,
			"PASS M6 uncontrolled keeper shadow updates (%.2f)" % ivo_shadow.value,
			"FAIL M6 uncontrolled shadow %.2f, expected 0.90" % ivo_shadow.value)
		_clear_bursts()
		maren_shadow.value = 1.0
		ivo_shadow.value = 1.0
		_advance(4)

func _lamp_room_step() -> void:
	if step_frame == 1:
		maren.position = Vector2(160, 210)
		ivo.position = Vector2(400, 400)
	elif step_frame == 5:
		switcher.switch_next()
	elif step_frame == 10:
		ivo_guard = ivo.position
		switcher.switch_next()
	elif step_frame == 15:
		_expect(maren.controlled and not ivo.controlled,
			"PASS M6 switching while in the lamp room works", "FAIL M6 lamp-room switch failed")
		_expect(beam.operator == maren and beam.manual_control,
			"PASS M6 controlled lamp-room keeper returns to manual aim",
			"FAIL M6 beam stayed in auto mode")
		_expect(camera.target_override == maren,
			"PASS M6 camera returns to the lamp-room keeper", "FAIL M6 camera target is wrong")
		_expect(ivo.position.distance_to(ivo_guard) < 0.5,
			"PASS M6 street keeper keeps guarding", "FAIL M6 street keeper moved")
		_advance(5)

func _readout_step() -> void:
	if step_frame < 3:
		return
	_expect(readout.text.contains("Active") and readout.text.contains("Maren") and readout.text.contains("Ivo"),
		"PASS M6 readout shows active keeper and both shadows", "FAIL M6 readout: %s" % readout.text)
	_advance(6)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M6 TESTS PASS")
	else:
		print("M6 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M6 RUNTIME CHECK START")
	switcher.switch_next()
	Clock.dawnglass_charge = 1.0
	maren_shadow.value = 1.0
	ivo_shadow.value = 1.0

func _runtime_tick() -> void:
	runtime_left -= 1
	runtime_frame += 1
	if runtime_frame % 120 == 0 and _creature_count() < 8:
		var sector := 30.0 + float((spawn_index * 37) % 120)
		spawn_index += 1
		var offset := Vector2.RIGHT.rotated(deg_to_rad(sector)) * 240.0
		_spawn(WALKER_SCENE, beam.global_position + offset)
	if runtime_left <= 0:
		print("M6 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var creature := scene.instantiate()
	add_child(creature)
	creature.global_position = at
	return creature

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
		if field == beam:
			continue
		field.queue_free()

func _creature_count() -> int:
	return get_tree().get_nodes_in_group("creatures").size()

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
