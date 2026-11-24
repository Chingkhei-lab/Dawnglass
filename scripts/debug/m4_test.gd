extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 3000
const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")
const LURKER_SCENE := preload("res://scenes/creatures/lurker.tscn")
const BURST_SCENE := preload("res://scenes/lights/glint_burst.tscn")

var failures := 0
var testing := true
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var runtime_frame := 0

var keeper: Node
var villager: Node2D
var readout: Label
var person_taken_count := 0
var walker: Node
var lurker: Node
var walker_start_distance := 0.0
var target_before: Node
var lurker_start := Vector2.ZERO
var fps_sum := 0.0
var fps_samples := 0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	keeper = $Maren
	villager = $Villager
	readout = $UI/Panel/Readout
	Events.person_taken.connect(_on_person_taken)
	print("M4 TEST START")

func _on_person_taken() -> void:
	person_taken_count += 1

func _physics_process(_delta: float) -> void:
	if not testing:
		_runtime_tick()
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M4 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _walker_step()
		2: _walker_lantern_step()
		3: _lurker_lantern_step()
		4: _lurker_person_step()
		5: _daylight_step()
		6: _sleeper_step()
		7: _lean_step()
		8: _readout_step()
		9: _finish_step()

func _structure_step() -> void:
	if step_frame < 2:
		return
	_expect(villager.is_in_group("persons") and villager.is_takeable(),
		"PASS M4 villager starts as a takeable person", "FAIL M4 villager is not a takeable person")
	_expect(GameState.sleepers.is_empty(),
		"PASS M4 no sleepers recorded at start", "FAIL M4 sleepers already recorded")
	_expect(keeper.is_in_group("persons") and keeper.has_method("take_shadow"),
		"PASS M4 keeper is a takeable person", "FAIL M4 keeper is not a takeable person")
	_expect(keeper.has_method("shadow_lean"),
		"PASS M4 keeper exposes shadow lean", "FAIL M4 keeper has no shadow lean")
	_advance(1)

func _walker_step() -> void:
	if step_frame == 1:
		villager.position = Vector2(700, 320)
		keeper.position = Vector2(200, 520)
		walker = _spawn(WALKER_SCENE, Vector2(500, 200))
		walker_start_distance = walker.global_position.distance_to(villager.global_position)
	elif step_frame == 121:
		var distance: float = walker.global_position.distance_to(villager.global_position)
		var moved := walker_start_distance - distance
		_expect(moved > 40.0,
			"PASS M4 Walker closes on nearest person (%.1f px)" % moved,
			"FAIL M4 Walker only moved %.1f px" % moved)
		_expect(walker.target == villager,
			"PASS M4 Walker targets the nearest person", "FAIL M4 Walker target is wrong")
		_clear_creatures()
		_advance(2)

func _walker_lantern_step() -> void:
	if step_frame == 1:
		villager.position = Vector2(550, 320)
		keeper.position = Vector2(200, 520)
		keeper.set_lantern(false)
		walker = _spawn(WALKER_SCENE, Vector2(400, 300))
	elif step_frame == 10:
		target_before = walker.target
		_expect(target_before == villager,
			"PASS M4 Walker targets villager before lantern toggled",
			"FAIL M4 Walker target before toggle is wrong")
		keeper.set_lantern(true)
	elif step_frame == 20:
		_expect(walker.target == villager,
			"PASS M4 Walker ignores a lit lantern", "FAIL M4 Walker diverted toward lantern")
		_expect(not villager.taken,
			"PASS M4 Walker did not take the villager from a distance", "FAIL M4 villager taken early")
		keeper.set_lantern(false)
		_clear_creatures()
		_advance(3)

func _lurker_lantern_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(300, 190)
		keeper.set_lantern(false)
		villager.position = Vector2(800, 320)
		lurker = _spawn(LURKER_SCENE, Vector2(300, 320))
		lurker_start = lurker.global_position
	elif step_frame == 60:
		var moved: float = lurker.global_position.distance_to(lurker_start)
		_expect(lurker.state == "hidden" and moved < 2.0,
			"PASS M4 Lurker waits while the lantern is unlit",
			"FAIL M4 Lurker moved %.1f px without a lit lantern" % moved)
		keeper.set_lantern(true)
	elif step_frame == 64:
		_expect(lurker.state == "rush" and lurker.target == keeper,
			"PASS M4 Lurker notices a lit lantern at range",
			"FAIL M4 Lurker did not notice the lit lantern")
		keeper.set_lantern(false)
		_clear_creatures()
		_advance(4)

func _lurker_person_step() -> void:
	if step_frame == 1:
		keeper.set_lantern(false)
		villager.position = Vector2(380, 320)
		lurker = _spawn(LURKER_SCENE, Vector2(300, 320))
	elif step_frame == 5:
		_expect(lurker.state == "rush" and lurker.target == villager,
			"PASS M4 Lurker rushes a person who comes near",
			"FAIL M4 Lurker ignored a nearby person")
		_clear_creatures()
		_advance(5)

func _daylight_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(900, 80)
		keeper.set_lantern(true)
		villager.position = Vector2(700, 320)
		_spawn(WALKER_SCENE, Vector2(600, 200))
		_spawn(LURKER_SCENE, Vector2(650, 200))
	elif step_frame == 31:
		_expect(_creature_count() == 2,
			"PASS M4 lantern light leaves creatures alive",
			"FAIL M4 creatures died with only a lantern (%d left)" % _creature_count())
		_spawn_burst(Vector2(625, 200), 2.0)
	elif step_frame == 36:
		_expect(_creature_count() == 0,
			"PASS M4 Glint daylight destroys both creatures",
			"FAIL M4 %d creatures survived the Glint" % _creature_count())
		_clear_bursts()
		keeper.set_lantern(false)
		_advance(6)

func _sleeper_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(200, 520)
		villager.position = Vector2(700, 320)
		person_taken_count = 0
		_spawn(WALKER_SCENE, Vector2(700, 270))
	elif step_frame == 121:
		_expect(villager.taken and is_instance_valid(villager),
			"PASS M4 taken villager stays in the world as a Sleeper",
			"FAIL M4 villager did not become a Sleeper")
		_expect(not villager.is_takeable(),
			"PASS M4 Sleeper can no longer act", "FAIL M4 Sleeper is still takeable")
		_expect(GameState.sleepers.has("villager"),
			"PASS M4 Sleeper is marked in GameState", "FAIL M4 Sleeper not marked in GameState")
		_expect(person_taken_count == 1,
			"PASS M4 person_taken fired once", "FAIL M4 person_taken fired %d times" % person_taken_count)
		_expect(_creature_count() == 0,
			"PASS M4 creature leaves after taking a shadow", "FAIL M4 creature stayed after taking")
		_advance(7)

func _lean_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(300, 520)
		_spawn(WALKER_SCENE, Vector2(350, 520))
	elif step_frame == 5:
		var lean: Vector2 = keeper.shadow_lean()
		_expect(lean.length() > 0.5 and lean.x > 0.0,
			"PASS M4 shadow leans toward a nearby creature (%.1f px)" % lean.length(),
			"FAIL M4 shadow lean is %s" % lean)
	elif step_frame == 6:
		for creature in get_tree().get_nodes_in_group("creatures"):
			creature.global_position = Vector2(500, 520)
	elif step_frame == 8:
		_expect(keeper.shadow_lean().length() < 0.001,
			"PASS M4 shadow does not lean beyond the tuned range",
			"FAIL M4 shadow leans beyond range: %s" % keeper.shadow_lean())
		_clear_creatures()
		_advance(8)

func _readout_step() -> void:
	if step_frame < 3:
		return
	_expect(readout.text.contains("Creatures") and readout.text.contains("Sleepers"),
		"PASS M4 readout shows creatures and sleepers", "FAIL M4 readout: %s" % readout.text)
	_advance(9)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M4 TESTS PASS")
	else:
		print("M4 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M4 RUNTIME CHECK START")

func _runtime_tick() -> void:
	runtime_left -= 1
	runtime_frame += 1
	if runtime_frame == 1:
		_spawn_perf_creatures()
	elif runtime_frame > 60 and runtime_frame <= 660:
		fps_sum += float(Engine.get_frames_per_second())
		fps_samples += 1
	elif runtime_frame == 661:
		_check_performance()
		_clear_creatures()
	if runtime_left <= 0:
		print("M4 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _spawn_perf_creatures() -> void:
	var count := int(Data.require_value("creatures.fps_count"))
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var offset := Vector2(cos(angle), sin(angle)) * 120.0
		var creature := _spawn(WALKER_SCENE, keeper.global_position + offset)
		creature.contact_enabled = false
	_expect(_creature_count() == count,
		"PASS M4 %d creatures spawned for the FPS check" % count,
		"FAIL M4 only %d creatures spawned" % _creature_count())

func _check_performance() -> void:
	var average := fps_sum / maxf(float(fps_samples), 1.0)
	var target := float(Data.require_value("creatures.fps_target"))
	_expect(average >= target,
		"PASS M4 40 creatures average %.0f FPS" % average,
		"FAIL M4 40 creatures average %.0f FPS" % average)

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
		field.queue_free()

func _clear_creatures() -> void:
	for creature in get_tree().get_nodes_in_group("creatures"):
		creature.queue_free()

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
