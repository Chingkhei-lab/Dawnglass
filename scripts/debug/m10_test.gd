extends Node2D

const RUNTIME_FRAMES := 10800
const RUNTIME_MSEC := 180000
const STEP_TIMEOUT := 5000
const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")
const LURKER_SCENE := preload("res://scenes/creatures/lurker.tscn")
var failures := 0
var testing := true
var load_mode := false
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var runtime_deadline := 0
var runtime_complete := false
var saved_text := ""
var saved_payload: Dictionary = {}
var dawn_seen := false
var dawn_phase_frames := 0
var slice: Node
var maren: Node
var ivo: Node
var switcher: Node
var beam: Node
var board: Node
var stats: Node
var chapel: Node
var hud: Control
var summary: Control
var dialogue: Node
var ferrow: Node
var odile: Node
var vell: Node
var walker: Node
var nightfall_button: Button
func _ready() -> void:
	Clock.time_scale = 0.0
	slice = $Slice
	maren = slice.get_node("Maren")
	ivo = slice.get_node("Ivo")
	switcher = slice.get_node("KeeperSwitch")
	beam = slice.get_node("Lighthouse/Beam")
	board = slice.get_node("PromiseBoard")
	stats = slice.get_node("NightStats")
	chapel = slice.get_node("Chapel")
	hud = slice.get_node("UI/KeeperHud")
	summary = slice.get_node("UI/DawnSummary")
	dialogue = slice.get_node("UI/DialogueBox")
	ferrow = slice.get_node("Ferrow")
	odile = slice.get_node("Odile")
	vell = slice.get_node("Vell")
	nightfall_button = slice.get_node("UI/Controls/NightfallButton")
	slice.spawning_enabled = false
	load_mode = (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--m10-load")
	if load_mode:
		step = 90
		print("M10 LOAD TEST START")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.SAVE_PATH))
		slice.reset_slice()
		print("M10 TEST START")
func _process(_delta: float) -> void:
	if testing:
		return
	if runtime_deadline == 0:
		runtime_deadline = Time.get_ticks_msec() + RUNTIME_MSEC
	if Time.get_ticks_msec() >= runtime_deadline:
		_complete_runtime()

func _physics_process(_delta: float) -> void:
	if not testing:
		runtime_left -= 1
		if summary.visible:
			summary.dismiss()
		if runtime_left <= 0:
			_complete_runtime()
		return
	step_frame += 1
	if step_frame > STEP_TIMEOUT:
		_expect(false, "", "FAIL M10 step %d timed out" % step)
		_finish()
		return
	match step:
		0: _structure_step()
		1: _day_step()
		2: _night_step()
		3: _dawn_step()
		4: _clear_step()
		5: _save_step()
		6: _cycle_step()
		7: _finish_step()
		90: _restart_step()
		91: _restart_dawn_step()

func _structure_step() -> void:
	if step_frame < 3:
		return
	_expect(slice.scene_file_path == "res://scenes/world/hollin_cove.tscn", "PASS M10 debug run uses the real slice scene", "FAIL M10 wrong scene")
	_expect(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/world/hollin_cove.tscn", "PASS M10 main scene is the playable slice", "FAIL M10 main scene")
	_expect(get_tree().get_nodes_in_group("keepers").size() == 2 and get_tree().get_nodes_in_group("townsfolk").size() == 3, "PASS M10 two keepers and three townsfolk share the area", "FAIL M10 population")
	_expect(get_tree().get_nodes_in_group("houses").size() == 3 and get_tree().get_nodes_in_group("hall").size() == 1 and get_tree().get_nodes_in_group("chapel_beds").size() == 1, "PASS M10 three homes, Hall and chapel are present", "FAIL M10 buildings")
	_expect(Clock.day == 1 and Clock.phase == Clock.PHASE_DAY and GameState.sleepers == ["absent"] and nightfall_button.visible and not nightfall_button.disabled, "PASS M10 day one starts with Nightfall available", "FAIL M10 initial state")
	_expect(maren.controlled and not ivo.controlled and beam.operator == maren, "PASS M10 Maren starts in the lamp room and Ivo on the street", "FAIL M10 keeper roles")
	_expect(not beam.is_beam_on() and get_tree().get_nodes_in_group("creatures").is_empty(), "PASS M10 the day starts dark and creature-free", "FAIL M10 daytime spawn/beam")
	_expect(get_tree().get_nodes_in_group("night_stats").size() == 1 and get_tree().get_nodes_in_group("dawn_summary").size() == 1 and get_tree().get_nodes_in_group("dialogue_boxes").size() == 1, "PASS M10 reporting and dialogue are wired into the slice", "FAIL M10 UI systems")
	_advance(1)

func _day_step() -> void:
	if step_frame == 1:
		Clock.dawnglass_charge = 1.0
		switcher.select_keeper(ivo)
		ferrow.interact()
		dialogue.choose(0)
	elif step_frame == 5:
		_expect(not beam.is_beam_on() and Clock.dawnglass_charge == 1.0, "PASS M10 the staffed beam stays off while the crystal charges", "FAIL M10 daytime beam")
		_expect(GameState.promises.size() == 1 and GameState.promises[0]["npc_id"] == "ferrow" and GameState.promises[0]["keeper_name"] == "Ivo", "PASS M10 Ferrow's dialogue creates a real promise", "FAIL M10 promise dialogue")
		_expect(hud.keeper_label.text == "IVO", "PASS M10 HUD follows the street keeper", "FAIL M10 HUD switch")
		ivo.global_position = ferrow.global_position + Vector2(0, 50)
		ivo.set_lantern(true)
		_advance(2)

func _night_step() -> void:
	if step_frame == 1:
		Clock.time_scale = 1.0
		slice.spawning_enabled = true
		nightfall_button.pressed.emit()
	elif step_frame == 300:
		_expect(Clock.phase == Clock.PHASE_NIGHT and Clock.dawnglass_charge > 0.9 and not nightfall_button.visible and slice.wave == 1 and not get_tree().get_nodes_in_group("creatures").is_empty(), "PASS M10 Nightfall skips day, charges the beam and spawns the first wave", "FAIL M10 Nightfall button")
		slice.spawning_enabled = false
		slice.clear_transients()
	elif step_frame == 360:
		_expect(odile.global_position.distance_to(odile.home) > 96.0 and vell.global_position.distance_to(vell.home) > 96.0, "PASS M10 Odile and Vell leave their homes for the Hall", "FAIL M10 dusk routine")
		_expect(ferrow.global_position.distance_to(ferrow.home) < 1.0, "PASS M10 Old Ferrow refuses to leave home", "FAIL M10 Ferrow routine")
		_expect(beam.operator == maren and not beam.manual_control and beam.is_beam_on(), "PASS M10 the abandoned lamp room runs an automatic beam", "FAIL M10 auto beam")
		_expect(odile.is_in_group("persons") and odile.is_takeable() and vell.is_takeable(), "PASS M10 townsfolk are valid creature targets", "FAIL M10 townsperson protocol")
		Clock.time_scale = 0.0
		_advance(3)

func _dawn_step() -> void:
	if step_frame == 1:
		slice.get_node("VellHouse").set("_was_lit", true)
		walker = _spawn_walker(odile.global_position)
		var victim_walker := _spawn_walker(ivo.global_position + Vector2(28, 0))
		ivo.fire_glint()
		victim_walker.set_meta("expected_destroyed", true)
	elif step_frame == 8:
		_expect(odile.taken and GameState.sleepers.has("odile"), "PASS M10 a creature can take a townsperson", "FAIL M10 townsperson taken")
		_expect(not is_instance_valid(walker) and stats.creatures_destroyed == 1, "PASS M10 Ivo's Glint destroys a Walker in the real area", "FAIL M10 Glint integration")
	elif step_frame == 660:
		_expect(float(GameState.promises[0]["lit"]) >= float(GameState.promises[0]["required"]), "PASS M10 Ivo's lantern keeps Ferrow's promise lit", "FAIL M10 promise light")
		Clock.phase = Clock.PHASE_DAWN
		Events.dawn.emit()
	elif step_frame == 670:
		var report: Dictionary = summary.last_report
		_expect(summary.visible and not report["safe"].has("Odile") and report["sleepers"].has("Odile"), "PASS M10 dawn summary reports the taken townsperson", "FAIL M10 dawn report")
		_expect(int(report["promises_kept"]) == 1 and int(report["creatures_destroyed"]) == 1, "PASS M10 dawn includes the kept promise and destroyed creature", "FAIL M10 dawn totals")
		_expect(chapel.occupied_count() == 2 and odile.global_position.distance_to(chapel.bed_position_for("odile")) < 0.1, "PASS M10 the taken townsperson wakes in a chapel bed", "FAIL M10 chapel placement")
		_expect(slice.get_node("OdileHouse").state() == "hollow" and slice.get_node("VellHouse").state() == "home" and slice.get_node("FerrowHouse").state() == "home", "PASS M10 only the empty unlit home becomes hollow", "FAIL M10 hollow choice")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_E
		key.pressed = true
		summary._unhandled_input(key)
		_expect(not summary.visible, "PASS M10 E dismisses the dawn summary", "FAIL M10 summary dismissal")
		_advance(4)

func _clear_step() -> void:
	if step_frame == 1:
		Clock.phase = Clock.PHASE_DAY
		ivo.global_position = slice.get_node("OdileHouse").global_position + Vector2(0, 50)
		ivo.set_lantern(true)
		ivo.fire_glint()
	elif step_frame == 8:
		_expect(slice.get_node("OdileHouse").state() == "home", "PASS M10 lantern plus Glint clears the hollow next morning", "FAIL M10 hollow clear")
		_expect(odile.taken and odile.global_position.distance_to(chapel.bed_position_for("odile")) < 0.1, "PASS M10 clearing the house does not wake its Sleeper", "FAIL M10 Sleeper stayed home")
		_advance(5)

func _save_step() -> void:
	if step_frame == 1:
		slice.reset_slice()
		board.accept("ferrow", "Old Ferrow", ferrow.home, ivo)
		Clock.phase = Clock.PHASE_NIGHT
		Clock.dawnglass_charge = 0.6
		ivo.global_position = Vector2(470, 520)
		ivo.fire_glint()
		walker = _spawn_walker(Vector2(900, 600))
		walker.name = "SavedWalker"
		var lurker := _spawn_lurker(Vector2(980, 600))
		lurker.name = "SavedLurker"
		lurker.set("state", "rush")
		lurker.set("target", vell)
		GameState.trust = 4
	elif step_frame == 5:
		GameState.promises[0]["lit"] = 3.0
		_expect(SaveSystem.save_game(), "PASS M10 the real slice saves", "FAIL M10 save")
		_read_save()
		var actors: Dictionary = saved_payload["actors"]
		_expect(actors.has("SavedWalker") and actors.has("SavedLurker") and actors.has("Glint_Ivo_1") and actors.has("slice"), "PASS M10 save includes both creature types, light and spawner state", "FAIL M10 transient save")
		slice.clear_transients()
		GameState.trust = -9
		Clock.day = 99
		ivo.global_position = Vector2(100, 100)
	elif step_frame == 7:
		_expect(SaveSystem.load_game(), "PASS M10 the real slice loads", "FAIL M10 load")
		_expect(SaveSystem.canonical_state() == saved_text, "PASS M10 slice save-load-save is byte-identical", "FAIL M10 deterministic slice save")
		_expect(GameState.trust == 4 and Clock.day == 1 and get_tree().get_nodes_in_group("creatures").size() == 2 and get_tree().get_nodes_in_group("glint_bursts").size() == 1, "PASS M10 load restores world state and transient night objects", "FAIL M10 restored slice")
		var saved_lurker := get_tree().current_scene.get_node_or_null("SavedLurker")
		_expect(saved_lurker != null and saved_lurker.get("state") == "rush" and saved_lurker.get("target") == vell, "PASS M10 a rushing Lurker restores its state and target", "FAIL M10 Lurker restore")
		_expect(SaveSystem.save_game() and FileAccess.get_file_as_string(SaveSystem.SAVE_PATH) == saved_text, "PASS M10 restored slice re-saves identically", "FAIL M10 re-save")
		_advance(6)

func _cycle_step() -> void:
	if step_frame == 1:
		slice.reset_slice()
		slice.spawning_enabled = true
		Clock.time_scale = float(Data.require_value("clock.test_time_scale"))
		dawn_seen = false
		dawn_phase_frames = 0
	if Clock.phase == Clock.PHASE_DAWN:
		dawn_phase_frames += 1
	if Clock.phase == Clock.PHASE_DAWN and not dawn_seen and dawn_phase_frames > 5:
		dawn_seen = true
		_expect(summary.visible and int(GameState.last_dawn.get("day", 0)) == 1, "PASS M10 accelerated play reaches a complete dawn report", "FAIL M10 full dawn")
		summary.dismiss()
	if Clock.day == 2 and Clock.phase == Clock.PHASE_DAY:
		_expect(Clock.dawnglass_charge > 0.0 and get_tree().get_nodes_in_group("creatures").is_empty(), "PASS M10 a full day and night finishes and the next day charges", "FAIL M10 full cycle")
		Clock.time_scale = 0.0
		_advance(7)

func _restart_step() -> void:
	if step_frame != 1:
		return
	_read_save()
	var actual_text := SaveSystem.canonical_state()
	if actual_text != saved_text:
		print("M10 RESTART EXPECTED SNAPSHOT\n%s" % saved_text)
		print("M10 RESTART ACTUAL SNAPSHOT\n%s" % actual_text)
	_expect(actual_text == saved_text, "PASS M10 quit-restart-load matches the saved slice", "FAIL M10 restart snapshot")
	_expect(GameState.trust == 4 and Clock.phase == Clock.PHASE_NIGHT and get_tree().get_nodes_in_group("creatures").size() == 2, "PASS M10 restart restores the live night", "FAIL M10 restart state")
	Clock.phase = Clock.PHASE_DAWN
	Events.dawn.emit()
	_advance(91)

func _restart_dawn_step() -> void:
	if step_frame < 5:
		return
	_expect(summary.visible and int(summary.last_report.get("promises_broken", 0)) == 1, "PASS M10 loaded promise settles after restart", "FAIL M10 restart dawn")
	_expect(get_tree().get_nodes_in_group("creatures").is_empty() and chapel.occupied_count() == GameState.sleepers.size(), "PASS M10 restart dawn clears creatures and fills beds", "FAIL M10 restart cleanup")
	get_tree().quit(failures)

func _finish_step() -> void:
	if step_frame < 2:
		return
	_finish()

func _complete_runtime() -> void:
	if runtime_complete:
		return
	runtime_complete = true
	print("M10 RUNTIME CHECK COMPLETE")
	get_tree().quit(failures)

func _finish() -> void:
	testing = false
	print("M10 TESTS PASS" if failures == 0 else "M10 TESTS FAIL (%d failures)" % failures)
	if (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast"):
		get_tree().quit(failures)
		return
	print("M10 RUNTIME CHECK START")
	slice.reset_slice()
	slice.spawning_enabled = true
	Clock.time_scale = float(Data.require_value("clock.test_time_scale"))

func _spawn_walker(at: Vector2) -> Node:
	var creature := WALKER_SCENE.instantiate()
	slice.add_child(creature)
	creature.global_position = at
	return creature

func _spawn_lurker(at: Vector2) -> Node:
	var creature := LURKER_SCENE.instantiate()
	slice.add_child(creature)
	creature.global_position = at
	return creature

func _read_save() -> void:
	saved_text = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)
	saved_payload = JSON.parse_string(saved_text)

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
