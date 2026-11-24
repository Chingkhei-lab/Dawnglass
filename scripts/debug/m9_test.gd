extends Node2D

const RUNTIME_FRAMES := 10800
const STEP_TIMEOUT := 3000
const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")
const GLINT_SCENE := preload("res://scenes/lights/glint_burst.tscn")

var failures := 0
var testing := true
var load_mode := false
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var runtime_frame := 0
var saved_text := ""
var saved_payload: Dictionary = {}
var maren: Node
var ivo: Node
var villager: Node
var switcher: Node
var board: Node
var stats: Node
var chapel: Node
var hud: Control
var summary: Control
var maren_shadow: Node
var ivo_shadow: Node
var walker: Node

func _ready() -> void:
	Clock.time_scale = 0.0
	Clock.day = 1
	Clock.phase = Clock.PHASE_NIGHT
	Clock.phase_elapsed = 0.0
	Clock.dawnglass_charge = 0.5
	maren = $Maren
	ivo = $Ivo
	villager = $Villager
	switcher = $KeeperSwitch
	board = $PromiseBoard
	stats = $NightStats
	chapel = $Chapel
	hud = $UI/KeeperHud
	summary = $UI/DawnSummary
	maren_shadow = maren.get_node("ShadowComponent")
	ivo_shadow = ivo.get_node("ShadowComponent")
	load_mode = (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--m9-load")
	if load_mode:
		step = 90
		print("M9 LOAD TEST START")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.SAVE_PATH))
		print("M9 TEST START")

func _physics_process(_delta: float) -> void:
	if not testing:
		_runtime_tick()
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M9 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _hud_step()
		2: _night_step()
		3: _save_step()
		4: _load_step()
		5: _finish_step()
		90: _restart_load_step()
		91: _restart_dawn_step()

func _structure_step() -> void:
	if step_frame < 3:
		return
	_expect(get_tree().get_nodes_in_group("keepers").size() == 2, "PASS M9 two keepers are available", "FAIL M9 keeper count")
	_expect(get_tree().get_nodes_in_group("night_stats").size() == 1 and get_tree().get_nodes_in_group("dawn_summary").size() == 1,
		"PASS M9 night stats and dawn summary are registered", "FAIL M9 report nodes missing")
	_expect(get_tree().get_nodes_in_group("chapel_beds").size() == 1, "PASS M9 chapel beds are registered", "FAIL M9 chapel missing")
	_expect(Events.has_signal("creature_destroyed") and Events.has_signal("state_loaded"),
		"PASS M9 destruction and load signals exist", "FAIL M9 signals missing")
	_expect(hud.keeper_label.text == "MAREN" and hud.shadow_label.text == "SHADOW NORMAL",
		"PASS M9 HUD starts on Maren's normal shadow", "FAIL M9 initial HUD")
	_expect(not summary.visible and not SaveSystem.has_save(), "PASS M9 summary and save slot start closed", "FAIL M9 initial UI/save state")
	_advance(1)

func _hud_step() -> void:
	if step_frame == 1:
		maren_shadow.value = 0.5
		maren_shadow.maximum = 0.9
		maren.glint_charges = 2
		Clock.day = 2
		Clock.dawnglass_charge = 0.42
	elif step_frame == 4:
		_expect(hud.shadow_label.text == "SHADOW FLICKERING", "PASS M9 HUD shows the flickering shadow stage", "FAIL M9 shadow stage")
		_expect(absf(hud.shadow_bar.scale.x - 0.5 / 0.9) < 0.01, "PASS M9 HUD shadow bar uses value over maximum", "FAIL M9 shadow bar")
		_expect(hud.glint_label.text.count("◆") == 2 and absf(hud.dawnglass_bar.scale.x - 0.42) < 0.01,
			"PASS M9 HUD shows Glint pips and stored Dawnglass", "FAIL M9 HUD resources")
		_expect(hud.time_label.text == "DAY 2 · NIGHT", "PASS M9 HUD shows day and phase", "FAIL M9 HUD time")
		switcher.select_keeper(ivo)
	elif step_frame == 7:
		_expect(hud.keeper_label.text == "IVO" and hud.shadow_label.text == "SHADOW NORMAL",
			"PASS M9 HUD follows the active keeper", "FAIL M9 HUD keeper switch")
		switcher.select_keeper(maren)
		maren_shadow.value = 1.0
		maren_shadow.maximum = 1.0
		maren.glint_charges = 3
		Clock.dawnglass_charge = 0.5
		_advance(2)

func _night_step() -> void:
	if step_frame == 1:
		Events.dusk_started.emit()
		villager.take_shadow()
		GameState.mark_sleeper("absent")
		Clock.phase = Clock.PHASE_DUSK
		board.accept("odile", "Odile", Vector2(500, 180), maren)
		board.accept("vell", "Sister Vell", Vector2(540, 180), maren)
		GameState.promises[0]["lit"] = float(GameState.promises[0]["required"])
		GameState.promises[1]["lit"] = 0.0
		Clock.phase = Clock.PHASE_NIGHT
		walker = WALKER_SCENE.instantiate()
		add_child(walker)
		walker.global_position = Vector2(850, 480)
		var burst := GLINT_SCENE.instantiate()
		add_child(burst)
		burst.global_position = walker.global_position
		burst.configure(float(Data.require_value("lighting.glint_radius")), 4.0, int(Data.require_value("lighting.obstacle_layer")))
	elif step_frame == 6:
		_expect(not is_instance_valid(walker) and stats.creatures_destroyed == 1,
			"PASS M9 daylight destruction fires one creature event", "FAIL M9 creature accounting")
	elif step_frame == 8:
		Clock.phase = Clock.PHASE_DAWN
		Events.dawn.emit()
	elif step_frame == 12:
		var report: Dictionary = summary.last_report
		var safe: Array = report.get("safe", [])
		var asleep: Array = report.get("sleepers", [])
		_expect(summary.visible and safe.has("Maren") and safe.has("Ivo") and safe.has("Odile") and not safe.has("Villager"),
			"PASS M9 dawn summary lists safe people and excludes the Sleeper", "FAIL M9 safe list")
		_expect(asleep.has("Villager") and asleep.has("Absent"), "PASS M9 dawn summary lists every Sleeper", "FAIL M9 Sleeper list")
		_expect(int(report.get("promises_kept", 0)) == 1 and int(report.get("promises_broken", 0)) == 1,
			"PASS M9 deferred summary includes settled promises", "FAIL M9 promise totals")
		_expect(int(report.get("creatures_destroyed", 0)) == 1, "PASS M9 summary includes creatures destroyed", "FAIL M9 creature total")
		_expect(chapel.occupied_count() == 2 and villager.global_position.distance_to(chapel.bed_position_for("villager")) < 0.1,
			"PASS M9 every Sleeper has a chapel bed and present bodies move there", "FAIL M9 bed placement")
		_expect(chapel.bed_position_for("absent") != Vector2.ZERO, "PASS M9 absent Sleeper bodies retain a bed marker", "FAIL M9 absent bed")
		_advance(3)

func _save_step() -> void:
	if step_frame < 2:
		return
	Clock.day = 3
	Clock.phase = Clock.PHASE_DAY
	GameState.promises.clear()
	board.accept("ferrow", "Old Ferrow", Vector2(555, 210), ivo)
	GameState.promises[0]["lit"] = 3.25
	Clock.phase = Clock.PHASE_NIGHT
	Clock.game_seconds = 1234.5
	Clock.phase_elapsed = 12.25
	Clock.dawnglass_charge = 0.37
	GameState.trust = 7
	GameState.bonds = {"odile": 3}
	GameState.inventory = {"shard": 4}
	GameState.flags = {"ferrow_promise": true}
	GameState.houses = {"odile": "hollow", "vell": "home"}
	maren.global_position = Vector2(310, 280)
	maren.velocity = Vector2(3, 0)
	maren.glint_charges = 2
	maren.set_lantern(true)
	maren_shadow.value = 0.44
	maren_shadow.maximum = 0.8
	maren_shadow._below_threshold = false
	maren_shadow._time = 8.5
	ivo_shadow.value = 0.25
	ivo_shadow.maximum = 0.75
	ivo_shadow._below_threshold = true
	ivo_shadow._time = 4.25
	switcher.select_keeper(ivo)
	Rng.seed_rng(9876)
	Rng.randf()
	summary.dismiss()
	_expect(SaveSystem.save_game(), "PASS M9 one-slot save writes successfully", "FAIL M9 save write")
	_read_save()
	var actors: Dictionary = saved_payload.get("actors", {})
	var promises: Array = saved_payload.get("game_state", {}).get("promises", [])
	_expect(actors.has("Maren") and actors.has("Ivo") and actors.has("villager") and promises.size() == 1,
		"PASS M9 save contains actors and pending promises", "FAIL M9 save contents")
	_advance(4)

func _load_step() -> void:
	if step_frame != 1:
		return
	GameState.trust = -10
	Clock.day = 99
	Clock.phase = Clock.PHASE_DAY
	Rng.seed_rng(1)
	maren.glint_charges = 0
	switcher.select_keeper(maren)
	_check_loaded()
	_expect(SaveSystem.save_game() and FileAccess.get_file_as_string(SaveSystem.SAVE_PATH) == saved_text,
		"PASS M9 save-load-save file is byte-identical", "FAIL M9 deterministic save")
	_advance(5)

func _restart_load_step() -> void:
	if step_frame != 1:
		return
	_read_save()
	_check_loaded()
	_expect(SaveSystem.save_game() and FileAccess.get_file_as_string(SaveSystem.SAVE_PATH) == saved_text,
		"PASS M9 quit-restart-load-save file is byte-identical", "FAIL M9 restart save")
	var rng_state: Dictionary = saved_payload.get("rng", {})
	var probe := RandomNumberGenerator.new()
	probe.state = int(String(rng_state.get("state", "0")))
	_expect(absf(Rng.randf() - probe.randf()) < 0.000001, "PASS M9 restored RNG continues the same sequence", "FAIL M9 RNG restore")
	Clock.phase = Clock.PHASE_DAWN
	Events.dawn.emit()
	_advance(91)

func _restart_dawn_step() -> void:
	if step_frame < 4:
		return
	_expect(summary.visible and int(summary.last_report.get("promises_broken", 0)) >= 2,
		"PASS M9 loaded promise settles in the next dawn summary", "FAIL M9 loaded dawn")
	_expect(chapel.occupied_count() == GameState.sleepers.size() and villager.global_position.distance_to(chapel.bed_position_for("villager")) < 0.1,
		"PASS M9 loaded Sleepers return to chapel beds at dawn", "FAIL M9 loaded beds")
	print("M9 LOAD TESTS PASS" if failures == 0 else "M9 LOAD TESTS FAIL (%d failures)" % failures)
	get_tree().quit(failures)

func _check_loaded() -> void:
	_expect(SaveSystem.load_game(), "PASS M9 one-slot load succeeds", "FAIL M9 load")
	var actual_text := SaveSystem.canonical_state()
	if actual_text != saved_text:
		print("M9 EXPECTED SNAPSHOT\n%s" % saved_text)
		print("M9 ACTUAL SNAPSHOT\n%s" % actual_text)
	_expect(actual_text == saved_text, "PASS M9 loaded snapshot matches the saved snapshot", "FAIL M9 snapshot mismatch")
	_expect(GameState.trust == 7 and Clock.day == 3 and Clock.phase == Clock.PHASE_NIGHT,
		"PASS M9 trust and clock state are restored", "FAIL M9 persistent state")
	_expect(switcher.active_keeper() == ivo and maren.glint_charges == 2 and absf(float(maren_shadow.value) - 0.44) < 0.0001,
		"PASS M9 active keeper, Glints and shadow are restored", "FAIL M9 keeper state")
	_expect(GameState.promises.size() == 1 and GameState.promises[0]["home"] is Vector2,
		"PASS M9 pending promise positions are restored as vectors", "FAIL M9 promise restore")

func _read_save() -> void:
	saved_text = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)
	saved_payload = JSON.parse_string(saved_text)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_finish()

func _finish() -> void:
	testing = false
	print("M9 TESTS PASS" if failures == 0 else "M9 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M9 RUNTIME CHECK START")
	Clock.time_scale = float(Data.require_value("clock.test_time_scale"))

func _runtime_tick() -> void:
	runtime_left -= 1
	runtime_frame += 1
	if summary.visible:
		summary.dismiss()
	if runtime_left <= 0:
		print("M9 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
