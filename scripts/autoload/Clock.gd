extends Node

const PHASE_DAY := "day"
const PHASE_DUSK := "dusk"
const PHASE_NIGHT := "night"
const PHASE_DAWN := "dawn"
const PHASE_ORDER := [PHASE_DAY, PHASE_DUSK, PHASE_NIGHT, PHASE_DAWN]
const PHASE_LENGTH_KEYS := {
	PHASE_DAY: "clock.day_length",
	PHASE_DUSK: "clock.dusk_length",
	PHASE_NIGHT: "clock.night_length",
	PHASE_DAWN: "clock.dawn_length",
}
const COLOR_NAMES := ["day", "dusk", "night", "dawn"]

var day: int = 1
var phase: String = PHASE_DAY
var game_seconds: float = 0.0
var phase_elapsed: float = 0.0
var dawnglass_charge: float = 0.0
var time_scale: float = 1.0

var _lengths: Dictionary = {}
var _colors: Dictionary = {}

func _ready() -> void:
	_load_config()
	time_scale = _cli_time_scale()

func _physics_process(delta: float) -> void:
	if phase_length() <= 0.0:
		return
	var step := delta * time_scale
	game_seconds += step
	phase_elapsed += step
	while phase_elapsed >= phase_length():
		phase_elapsed -= phase_length()
		_enter_next_phase()
	if phase == PHASE_DAY:
		var rate := 1.0 / maxf(phase_length(), 0.001)
		dawnglass_charge = minf(1.0, dawnglass_charge + step * rate)

func phase_length() -> float:
	return length_of(phase)

func length_of(current: String) -> float:
	return float(_lengths.get(current, 0.0))

func cycle_length() -> float:
	var total := 0.0
	for current in PHASE_ORDER:
		total += length_of(current)
	return total

func phase_progress() -> float:
	return clampf(phase_elapsed / maxf(phase_length(), 0.001), 0.0, 1.0)

func is_configured() -> bool:
	return not _lengths.is_empty() and cycle_length() > 0.0

func color_for(current: String) -> Color:
	return _colors.get(current, Color.WHITE)

func sky_color() -> Color:
	var progress := phase_progress()
	match phase:
		PHASE_DUSK:
			return _two_stage_color(_colors.day, _colors.dusk, _colors.night, progress)
		PHASE_DAWN:
			return _two_stage_color(_colors.night, _colors.dawn, _colors.day, progress)
		PHASE_NIGHT:
			return _colors.night
	return _colors.day

func _enter_next_phase() -> void:
	var index := PHASE_ORDER.find(phase)
	phase = PHASE_ORDER[(index + 1) % PHASE_ORDER.size()]
	match phase:
		PHASE_DAY:
			day += 1
			Events.day_started.emit()
		PHASE_NIGHT:
			Events.night_started.emit()
		PHASE_DAWN:
			Events.dawn.emit()

func _two_stage_color(from: Color, middle: Color, to: Color, progress: float) -> Color:
	var eased := smoothstep(0.0, 1.0, progress)
	if eased < 0.5:
		return from.lerp(middle, eased * 2.0)
	return middle.lerp(to, (eased - 0.5) * 2.0)

func _load_config() -> void:
	for current in PHASE_ORDER:
		_lengths[current] = _number(PHASE_LENGTH_KEYS[current])
	for color_name in COLOR_NAMES:
		_colors[color_name] = _color("clock.colors." + color_name)

func _cli_time_scale() -> float:
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with("--time-scale="):
			return maxf(float(arg.get_slice("=", 1)), 0.0001)
	return 1.0

func _number(path: String) -> float:
	var value = Data.require_value(path)
	return float(value) if value != null else 0.0

func _color(path: String) -> Color:
	var value = Data.require_value(path)
	return Color(String(value)) if value != null else Color.WHITE
