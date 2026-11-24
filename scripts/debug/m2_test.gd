extends Node2D

const RUNTIME_FRAMES := 10800
const DURATION_TOLERANCE := 1.0
const MAX_FRAME_COLOR_DELTA := 0.05
const MIN_TRANSITION_COLOR_CHANGE := 0.2
const MIN_TRANSITION_FRAMES := 30

var failures := 0
var runtime_left := RUNTIME_FRAMES
var testing := true

var cycle_start_seconds := 0.0
var expected_cycle := 0.0
var signal_log: Array[String] = []
var previous_phase := ""
var cycle_done := false

var day_charge_start := -1.0
var day_charge_checked := false
var day_color_checked := false
var night_checked := false
var readout_checked := false

var transition_phase := ""
var transition_first := Color.WHITE
var transition_last := Color.WHITE
var transition_max_delta := 0.0
var transition_frames := 0

@onready var tint: CanvasModulate = $Tint
@onready var readout: Label = $UI/Panel/Readout

func _ready() -> void:
	Clock.time_scale = _test_time_scale()
	Events.day_started.connect(_on_day_started)
	Events.night_started.connect(_on_night_started)
	Events.dawn.connect(_on_dawn)
	print("M2 TEST START")
	expected_cycle = Clock.cycle_length()
	cycle_start_seconds = Clock.game_seconds
	_initial_checks()

func _physics_process(_delta: float) -> void:
	if not testing:
		_runtime_tick()
		return
	if Clock.phase != previous_phase:
		_enter_phase(Clock.phase)
		previous_phase = Clock.phase
	match Clock.phase:
		Clock.PHASE_DAY:
			_test_daylight()
		Clock.PHASE_DUSK, Clock.PHASE_DAWN:
			_test_transition()
		Clock.PHASE_NIGHT:
			_test_night()
	if not cycle_done and Clock.game_seconds - cycle_start_seconds > expected_cycle + DURATION_TOLERANCE:
		cycle_done = true
		_expect(false, "", "FAIL M2 no day_started within %.1f s" % (expected_cycle + DURATION_TOLERANCE))
		_finish()

func _initial_checks() -> void:
	_expect(Clock.is_configured() and expected_cycle > 0.0,
		"PASS M2 clock configured (cycle %.1f s)" % expected_cycle,
		"FAIL M2 clock not configured")
	_expect(Clock.phase == Clock.PHASE_DAY,
		"PASS M2 starts in daylight", "FAIL M2 starts in %s" % Clock.phase)
	_expect(Clock.dawnglass_charge < 0.01,
		"PASS M2 Dawnglass starts empty", "FAIL M2 Dawnglass starts at %.2f" % Clock.dawnglass_charge)
	var day_length = Data.require_value("clock.day_length")
	_expect(day_length != null and is_equal_approx(Clock.length_of(Clock.PHASE_DAY), float(day_length)),
		"PASS M2 daylight length comes from tuning", "FAIL M2 daylight length not from tuning")

func _on_night_started() -> void:
	signal_log.append("night_started")
	_expect(Clock.dawnglass_charge >= 0.98,
		"PASS M2 Dawnglass charged through daylight (%d%%)" % roundi(Clock.dawnglass_charge * 100.0),
		"FAIL M2 Dawnglass charge %.2f at nightfall" % Clock.dawnglass_charge)

func _on_dawn() -> void:
	signal_log.append("dawn")

func _on_day_started() -> void:
	signal_log.append("day_started")
	if cycle_done:
		return
	_finish_transition_check()
	cycle_done = true
	var ordered := signal_log == ["night_started", "dawn", "day_started"]
	_expect(ordered,
		"PASS M2 cycle signals in order (%s)" % ", ".join(signal_log),
		"FAIL M2 cycle signals: %s" % ", ".join(signal_log))
	var measured := Clock.game_seconds - cycle_start_seconds
	_expect(absf(measured - expected_cycle) <= DURATION_TOLERANCE,
		"PASS M2 full cycle %.2f s (configured %.2f s)" % [measured, expected_cycle],
		"FAIL M2 cycle %.2f s vs configured %.2f s" % [measured, expected_cycle])
	_finish()

func _test_daylight() -> void:
	if not day_color_checked and Clock.phase_progress() > 0.05:
		day_color_checked = true
		_expect(_color_delta(tint.color, Clock.color_for(Clock.PHASE_DAY)) < 0.01,
			"PASS M2 daylight colour comes from tuning", "FAIL M2 daylight colour off")
	var progress := Clock.phase_progress()
	if day_charge_start < 0.0 and progress > 0.25:
		day_charge_start = Clock.dawnglass_charge
	elif not day_charge_checked and day_charge_start >= 0.0 and progress > 0.5:
		day_charge_checked = true
		_expect(Clock.dawnglass_charge > day_charge_start,
			"PASS M2 Dawnglass rises in daylight (%.2f -> %.2f)" % [day_charge_start, Clock.dawnglass_charge],
			"FAIL M2 Dawnglass did not rise (%.2f -> %.2f)" % [day_charge_start, Clock.dawnglass_charge])
	if not readout_checked and progress > 0.3:
		readout_checked = true
		var shown := readout.text
		_expect(shown.contains("DAY") and shown.contains("Dawnglass") and shown.contains("%"),
			"PASS M2 readout shows phase and Dawnglass charge (%s)" % shown,
			"FAIL M2 readout: %s" % shown)

func _test_night() -> void:
	if night_checked or Clock.phase_progress() < 0.02:
		return
	night_checked = true
	_expect(_color_delta(tint.color, Clock.color_for(Clock.PHASE_NIGHT)) < 0.02,
		"PASS M2 night colour comes from tuning", "FAIL M2 night colour off")

func _test_transition() -> void:
	if transition_phase == "":
		return
	transition_frames += 1
	transition_max_delta = maxf(transition_max_delta, _color_delta(transition_last, tint.color))
	transition_last = tint.color

func _enter_phase(current: String) -> void:
	_finish_transition_check()
	if current == Clock.PHASE_DUSK or current == Clock.PHASE_DAWN:
		transition_phase = current
		transition_first = tint.color
		transition_last = tint.color
		transition_max_delta = 0.0
		transition_frames = 0

func _finish_transition_check() -> void:
	if transition_phase == "":
		return
	if transition_frames >= MIN_TRANSITION_FRAMES:
		var change := _color_delta(transition_first, transition_last)
		_expect(transition_max_delta <= MAX_FRAME_COLOR_DELTA and change >= MIN_TRANSITION_COLOR_CHANGE,
			"PASS M2 %s light changes smoothly (step %.3f, range %.2f)" % [transition_phase, transition_max_delta, change],
			"FAIL M2 %s light not smooth (step %.3f, range %.2f)" % [transition_phase, transition_max_delta, change])
	transition_phase = ""

func _color_delta(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

func _finish() -> void:
	testing = false
	if failures == 0:
		print("M2 TESTS PASS")
	else:
		print("M2 TESTS FAIL (%d failures)" % failures)
	if _fast_mode():
		get_tree().quit(failures)
		return
	print("M2 RUNTIME CHECK START")

func _runtime_tick() -> void:
	runtime_left -= 1
	if runtime_left == 0:
		print("M2 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _fast_mode() -> bool:
	return (OS.get_cmdline_args() + OS.get_cmdline_user_args()).has("--fast")

func _test_time_scale() -> float:
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with("--time-scale="):
			return float(arg.get_slice("=", 1))
	var value = Data.require_value("clock.test_time_scale")
	return float(value) if value != null else 1.0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
