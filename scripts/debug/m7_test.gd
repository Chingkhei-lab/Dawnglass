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
var dialogue: CanvasLayer
var readout: Label
var maren_shadow: Node
var odile_home := Vector2.ZERO
var vell_home := Vector2.ZERO
var ferrow_home := Vector2.ZERO
var odile_start := Vector2.ZERO
var vell_start := Vector2.ZERO
var trust_before := 0
var kept_count := 0
var broken_count := 0
var odile_trust := 0
var vell_trust := 0
var kept_trust := 0
var broken_trust := 0
var max_bonus := 0.0
var lit_frames := 0

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.phase = Clock.PHASE_DAY
	Clock.phase_elapsed = 0.0
	GameState.trust = 0
	GameState.bonds.clear()
	GameState.flags.clear()
	GameState.promises.clear()
	maren = $Maren
	odile = $Odile
	vell = $Vell
	ferrow = $Ferrow
	hall = $Hall
	dialogue = $DialogueBox
	readout = $UI/Panel/Readout
	maren_shadow = maren.get_node("ShadowComponent")
	maren_shadow.value = 1.0
	maren_shadow.maximum = 1.0
	odile_home = odile.get("home")
	vell_home = vell.get("home")
	ferrow_home = ferrow.get("home")
	odile_trust = _choice_trust("odile")
	vell_trust = _choice_trust("vell")
	kept_trust = int(Data.require_value("promise.trust_kept"))
	broken_trust = int(Data.require_value("promise.trust_broken"))
	max_bonus = float(Data.require_value("promise.max_shadow_bonus"))
	lit_frames = int(ceil(float(Data.require_value("promise.lit_seconds")) * 60.0)) + 30
	Events.promise_kept.connect(_on_kept)
	Events.promise_broken.connect(_on_broken)
	var camera: Camera2D = $Camera2D
	camera.global_position = maren.global_position
	print("M7 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		runtime_left -= 1
		if runtime_left <= 0:
			print("M7 RUNTIME CHECK COMPLETE")
			get_tree().quit(failures)
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M7 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _dusk_step()
		2: _promise_step()
		3: _night_lit_step()
		4: _dawn_kept_step()
		5: _broken_step()
		6: _refusal_step()
		7: _readout_step()
		8: _finish_step()

func _structure_step() -> void:
	if step_frame < 3: return
	var folk := get_tree().get_nodes_in_group("townsfolk").size()
	_expect(folk == 3, "PASS M7 three townsfolk are registered", "FAIL M7 townsfolk count is %d" % folk)
	_expect(FileAccess.file_exists("res://data/dialogue/odile.json")
		and FileAccess.file_exists("res://data/dialogue/vell.json")
		and FileAccess.file_exists("res://data/dialogue/ferrow.json"),
		"PASS M7 dialogue data files exist", "FAIL M7 dialogue data is missing")
	_expect(Events.has_signal("dusk_started") and Events.has_signal("promise_broken"),
		"PASS M7 new signals are registered", "FAIL M7 dusk/promise signals missing")
	_expect(get_tree().get_first_node_in_group("promise_board") != null and GameState.promises.is_empty(),
		"PASS M7 promise board starts empty", "FAIL M7 promise board missing or dirty")
	_expect(not dialogue.is_open(), "PASS M7 dialogue starts closed", "FAIL M7 dialogue starts open")
	_advance(1)

func _dusk_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DUSK
		odile_start = odile.global_position
		vell_start = vell.global_position
		Events.dusk_started.emit()
		return
	if step_frame != 361:
		return
	var odile_hall: float = odile.global_position.distance_to(hall.global_position)
	var vell_hall: float = vell.global_position.distance_to(hall.global_position)
	_expect(odile_hall < 8.0 and vell_hall < 8.0,
		"PASS M7 Odile and Vell walk to the Hall at dusk (%.1f / %.1f px)" % [odile_hall, vell_hall],
		"FAIL M7 townsfolk missed the Hall (%.1f / %.1f px)" % [odile_hall, vell_hall])
	_expect(odile.global_position.distance_to(odile_start) > 100.0
		and vell.global_position.distance_to(vell_start) > 100.0,
		"PASS M7 the dusk walk is a real journey", "FAIL M7 townsfolk barely moved")
	var ferrow_home_distance: float = ferrow.global_position.distance_to(ferrow_home)
	_expect(ferrow_home_distance < 0.5 and ferrow.global_position.distance_to(hall.global_position) > 100.0,
		"PASS M7 Old Ferrow refuses and stays home",
		"FAIL M7 Ferrow moved %.1f px from home" % ferrow_home_distance)
	_advance(2)

func _promise_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DAY
		_place_maren_beside(odile)
	elif step_frame == 5:
		_expect(maren.try_interact() and dialogue.is_open(),
			"PASS M7 talking to Odile opens the dialogue box", "FAIL M7 dialogue did not open")
		_expect(dialogue.speaker_text().contains("Odile"),
			"PASS M7 dialogue names the speaker", "FAIL M7 speaker is '%s'" % dialogue.speaker_text())
	elif step_frame == 8:
		trust_before = GameState.trust
		_expect(dialogue.choose(0), "PASS M7 the promise option is accepted before night",
			"FAIL M7 promise option rejected")
		_expect(not dialogue.is_open(), "PASS M7 choosing a line closes the box", "FAIL M7 dialogue stayed open")
		_expect(GameState.trust == trust_before + odile_trust,
			"PASS M7 dialogue changed trust by the data value (%+d)" % odile_trust,
			"FAIL M7 trust %d, expected %d" % [GameState.trust, trust_before + odile_trust])
		_expect(int(GameState.bonds.get("odile", 0)) == 1 and GameState.promises.size() == 1,
			"PASS M7 bond and promise are recorded",
			"FAIL M7 bonds=%s promises=%d" % [str(GameState.bonds), GameState.promises.size()])
		if GameState.promises.size() == 1:
			var entry: Dictionary = GameState.promises[0]
			_expect(String(entry.get("npc_id", "")) == "odile"
				and String(entry.get("keeper_name", "")) == "Maren",
				"PASS M7 the promise is tied to the keeper who made it",
				"FAIL M7 promise entry is %s" % str(entry))
		_advance(3)

func _night_lit_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_NIGHT
		Clock.phase_elapsed = 0.0
		maren.global_position = odile_home + Vector2(0, 20)
		maren.set_lantern(true)
		return
	if step_frame != lit_frames:
		return
	var required := float(Data.require_value("promise.lit_seconds"))
	var lit := 0.0
	if not GameState.promises.is_empty():
		lit = float(GameState.promises[0].get("lit", 0.0))
	_expect(lit >= required, "PASS M7 the lantern keeps Odile's home lit (%.1f / %.1f s)" % [lit, required],
		"FAIL M7 promise only lit %.1f / %.1f s" % [lit, required])
	maren.set_lantern(false)
	_advance(4)

func _dawn_kept_step() -> void:
	if step_frame == 1:
		maren_shadow.maximum = 0.8
		maren_shadow.value = 0.8
		trust_before = GameState.trust
		Events.dawn.emit()
		Clock.phase = Clock.PHASE_DAWN
		return
	if step_frame != 3:
		return
	_expect(GameState.trust == trust_before + kept_trust,
		"PASS M7 a kept promise adds the tuned trust (%+d)" % kept_trust,
		"FAIL M7 trust %d, expected %d" % [GameState.trust, trust_before + kept_trust])
	_expect(absf(float(maren_shadow.maximum) - (0.8 + max_bonus)) < 0.001,
		"PASS M7 a kept promise raises the keeper's maximum shadow (%.2f)" % maren_shadow.maximum,
		"FAIL M7 maximum shadow is %.2f, expected %.2f" % [maren_shadow.maximum, 0.8 + max_bonus])
	_expect(GameState.promises.is_empty() and kept_count == 1 and broken_count == 0,
		"PASS M7 the kept promise is settled at dawn",
		"FAIL M7 promises=%d kept=%d broken=%d" % [GameState.promises.size(), kept_count, broken_count])
	_advance(5)

func _broken_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DAY
		_place_maren_beside(vell)
	elif step_frame == 5:
		_expect(maren.try_interact() and dialogue.is_open(),
			"PASS M7 Sister Vell can be talked to", "FAIL M7 Vell dialogue did not open")
	elif step_frame == 8:
		trust_before = GameState.trust
		_expect(dialogue.choose(0) and GameState.promises.size() == 1,
			"PASS M7 a second promise can be made",
			"FAIL M7 Vell promise not recorded (count %d)" % GameState.promises.size())
		_expect(GameState.trust == trust_before + vell_trust,
			"PASS M7 Vell's choice changed trust (%+d)" % vell_trust,
			"FAIL M7 trust %d, expected %d" % [GameState.trust, trust_before + vell_trust])
		Clock.phase = Clock.PHASE_NIGHT
		Clock.phase_elapsed = 0.0
		trust_before = GameState.trust
		Events.dawn.emit()
		Clock.phase = Clock.PHASE_DAWN
	elif step_frame == 10:
		_expect(GameState.trust == trust_before + broken_trust,
			"PASS M7 a broken promise costs the tuned trust (%+d)" % broken_trust,
			"FAIL M7 trust %d, expected %d" % [GameState.trust, trust_before + broken_trust])
		_expect(broken_count == 1 and kept_count == 1 and GameState.promises.is_empty(),
			"PASS M7 the broken promise is settled at dawn",
			"FAIL M7 broken=%d kept=%d promises=%d" % [broken_count, kept_count, GameState.promises.size()])
		_expect(absf(float(maren_shadow.maximum) - 0.9) < 0.001,
			"PASS M7 a broken promise does not raise the maximum",
			"FAIL M7 maximum shadow drifted to %.2f" % maren_shadow.maximum)
		_advance(6)

func _refusal_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_NIGHT
		Clock.phase_elapsed = 0.0
		trust_before = GameState.trust
		_expect(dialogue.open("ferrow"), "PASS M7 Old Ferrow's dialogue opens", "FAIL M7 Ferrow dialogue did not open")
		_expect(dialogue.speaker_text().contains("Ferrow"),
			"PASS M7 Old Ferrow is named", "FAIL M7 speaker is '%s'" % dialogue.speaker_text())
	elif step_frame == 4:
		_expect(not dialogue.choose(0), "PASS M7 a promise cannot be made at night",
			"FAIL M7 night promise was accepted")
		_expect(GameState.promises.is_empty() and GameState.trust == trust_before,
			"PASS M7 a late promise changes nothing",
			"FAIL M7 promises=%d trust=%d" % [GameState.promises.size(), GameState.trust])
		_expect(dialogue.is_open() and dialogue.body_text().contains("too late"),
			"PASS M7 the box explains the refusal", "FAIL M7 refusal text is '%s'" % dialogue.body_text())
		dialogue.close()
		_advance(7)

func _readout_step() -> void:
	if step_frame < 3: return
	_expect(readout.text.contains("Trust") and readout.text.contains("Promis"),
		"PASS M7 readout shows trust and pending promises", "FAIL M7 readout: %s" % readout.text)
	_advance(8)

func _finish_step() -> void: if step_frame >= 2: _finish()

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M7 TESTS PASS")
	else:
		print("M7 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M7 RUNTIME CHECK START")
	Clock.time_scale = float(Data.require_value("clock.test_time_scale"))
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	maren_shadow.value = 1.0
	maren_shadow.maximum = 1.0

func _place_maren_beside(npc: Node) -> void:
	var body := npc as Node2D
	if body != null:
		maren.global_position = body.global_position + Vector2(0, 22)

func _choice_trust(file_name: String) -> int:
	var file := FileAccess.open("res://data/dialogue/%s.json" % file_name, FileAccess.READ)
	if file == null:
		return 0
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 0
	var choices: Array = parsed.get("choices", [])
	if choices.is_empty():
		return 0
	return int(choices[0].get("trust", 0))

func _on_kept() -> void: kept_count += 1

func _on_broken() -> void: broken_count += 1

func _advance(next_step: int) -> void: step = next_step; step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
