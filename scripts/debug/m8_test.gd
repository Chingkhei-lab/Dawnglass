extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 4000

var failures := 0
var testing := true
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES

var maren: Node
var odile: Node
var vell: Node
var ferrow: Node
var hall: Node2D
var odile_house: Node
var vell_house: Node
var ferrow_house: Node
var readout: Label
var maren_shadow: Node

var odile_home := Vector2.ZERO
var vell_home := Vector2.ZERO
var ferrow_home := Vector2.ZERO
var hollowed_count := 0
var cleared_count := 0
var charges_before := 0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_DAY
	Clock.phase_elapsed = 0.0
	GameState.houses.clear()
	GameState.promises.clear()
	GameState.sleepers.clear()
	maren = $Maren
	odile = $Odile
	vell = $Vell
	ferrow = $Ferrow
	hall = $Hall
	odile_house = $OdileHouse
	vell_house = $VellHouse
	ferrow_house = $FerrowHouse
	readout = $UI/Panel/Readout
	maren_shadow = maren.get_node("ShadowComponent")
	maren_shadow.value = 1.0
	maren_shadow.maximum = 1.0
	odile_home = odile.get("home")
	vell_home = vell.get("home")
	ferrow_home = ferrow.get("home")
	Events.house_hollowed.connect(_on_hollowed)
	Events.house_cleared.connect(_on_cleared)
	var camera: Camera2D = $Camera2D
	camera.global_position = maren.global_position
	print("M8 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		runtime_left -= 1
		if runtime_left <= 0:
			print("M8 RUNTIME CHECK COMPLETE")
			get_tree().quit(failures)
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M8 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _night_step()
		2: _clear_step()
		3: _return_step()
		4: _readout_step()
		5: _finish_step()

func _structure_step() -> void:
	if step_frame < 3: return
	_expect(get_tree().get_nodes_in_group("houses").size() == 3,
		"PASS M8 three houses are registered", "FAIL M8 house count is %d" % get_tree().get_nodes_in_group("houses").size())
	_expect(get_tree().get_nodes_in_group("townsfolk").size() == 3,
		"PASS M8 each house has a townsperson", "FAIL M8 townsfolk count is %d" % get_tree().get_nodes_in_group("townsfolk").size())
	_expect(not odile_house.is_hollow() and not vell_house.is_hollow() and not ferrow_house.is_hollow(),
		"PASS M8 all houses start inhabited", "FAIL M8 a house starts hollow")
	_expect(Events.has_signal("house_hollowed") and Events.has_signal("house_cleared"),
		"PASS M8 house events are registered", "FAIL M8 house events missing")
	_expect(readout.text.contains("ODILE HOME") and readout.text.contains("VELL HOME"),
		"PASS M8 readout shows the starting house states", "FAIL M8 readout: %s" % readout.text)
	_advance(1)

func _night_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_NIGHT
		Clock.phase_elapsed = 0.0
		odile.global_position = hall.global_position
		vell.global_position = hall.global_position
		maren.global_position = vell_house.global_position + Vector2(0, 60)
		maren.set_lantern(true)
		Events.night_started.emit()
	elif step_frame == 6:
		Events.dawn.emit()
		Clock.phase = Clock.PHASE_DAWN
	elif step_frame == 9:
		_expect(odile_house.is_hollow(), "PASS M8 a dark empty home becomes hollow at dawn",
			"FAIL M8 Odile's dark house did not hollow")
		_expect(not vell_house.is_hollow(), "PASS M8 a lit empty home does not become hollow",
			"FAIL M8 Vell's lit house hollowed")
		_expect(not ferrow_house.is_hollow(), "PASS M8 an occupied home does not become hollow",
			"FAIL M8 Ferrow's occupied house hollowed")
		_expect(hollowed_count == 1, "PASS M8 hollowing fires one house event",
			"FAIL M8 hollowed event count is %d" % hollowed_count)
		_expect(odile.global_position.distance_to(hall.global_position) < 8.0,
			"PASS M8 the family cannot return to a hollow home", "FAIL M8 Odile left the Hall")
		_expect(ferrow.global_position.distance_to(ferrow_home) < 0.5,
			"PASS M8 stubborn Ferrow stays in his occupied home", "FAIL M8 Ferrow moved")
		maren.set_lantern(false)
		_advance(2)

func _clear_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DAY
		Clock.phase_elapsed = 0.0
		maren.global_position = odile_house.global_position + Vector2(0, 60)
		charges_before = maren.glint_charges
		_expect(maren.fire_glint(), "PASS M8 the keeper can fire a Glint at the hollow house",
			"FAIL M8 Glint could not be fired")
	elif step_frame == 6:
		_expect(odile_house.is_hollow(), "PASS M8 a Glint alone does not clear the house",
			"FAIL M8 house cleared without the lantern")
		_expect(maren.glint_charges == charges_before - 1,
			"PASS M8 clearing preparation spends one Glint charge", "FAIL M8 Glint charge did not decrease")
	elif step_frame == 8:
		maren.set_lantern(true)
	elif step_frame == 12:
		_expect(not odile_house.is_hollow(), "PASS M8 lantern plus Glint clears the hollow house",
			"FAIL M8 house stayed hollow with lantern and Glint")
		_expect(String(GameState.houses.get("odile", "")) == "home",
			"PASS M8 clearing changes the saved house state", "FAIL M8 house state is %s" % GameState.houses.get("odile", ""))
		_expect(cleared_count == 1, "PASS M8 clearing fires one house event",
			"FAIL M8 cleared event count is %d" % cleared_count)
		_advance(3)

func _return_step() -> void:
	if step_frame != 320: return
	_expect(odile.global_position.distance_to(odile_home) < 8.0,
		"PASS M8 the family moves back after the house is cleared",
		"FAIL M8 Odile is %.1f px from home" % odile.global_position.distance_to(odile_home))
	_expect(vell.global_position.distance_to(vell_home) < 8.0,
		"PASS M8 the lit home's family also returns normally",
		"FAIL M8 Vell is %.1f px from home" % vell.global_position.distance_to(vell_home))
	_expect(ferrow.global_position.distance_to(ferrow_home) < 0.5,
		"PASS M8 Ferrow remains at home", "FAIL M8 Ferrow drifted")
	_advance(4)

func _readout_step() -> void:
	if step_frame < 3: return
	_expect(readout.text.contains("ODILE HOME") and readout.text.contains("VELL HOME")
		and readout.text.contains("FERROW HOME"),
		"PASS M8 readout shows all restored house states", "FAIL M8 readout: %s" % readout.text)
	_advance(5)

func _finish_step() -> void: if step_frame >= 2: _finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M8 TESTS PASS")
	else:
		print("M8 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M8 RUNTIME CHECK START")
	Clock.time_scale = float(Data.require_value("clock.test_time_scale"))
	Clock.phase = Clock.PHASE_DAY
	Clock.phase_elapsed = 0.0
	maren.set_lantern(false)
	maren_shadow.value = 1.0
	maren_shadow.maximum = 1.0

func _on_hollowed(_house_id: String) -> void:
	hollowed_count += 1

func _on_cleared(_house_id: String) -> void:
	cleared_count += 1

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
