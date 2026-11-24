extends Node

const STAGE_NORMAL := "normal"
const STAGE_FLICKERING := "flickering"
const STAGE_FAINT := "faint"
const STAGE_GONE := "gone"

var value: float = 1.0
var maximum: float = 1.0
var _below_threshold := false
var _time := 0.0

var _loss_rate := 0.0
var _recovery_rate := 0.0
var _threshold := 0.3
var _max_drop := 0.1
var _flicker_speed := 6.0

func _ready() -> void:
	maximum = float(Data.require_value("shadow.maximum"))
	value = minf(float(Data.require_value("shadow.starting")), maximum)
	_loss_rate = float(Data.require_value("shadow.dawnglass_loss_rate"))
	_recovery_rate = float(Data.require_value("shadow.sunlight_recovery_rate"))
	_threshold = float(Data.require_value("shadow.low_threshold"))
	_max_drop = float(Data.require_value("shadow.max_drop"))
	_flicker_speed = float(Data.require_value("shadow.flicker_speed"))

func _physics_process(delta: float) -> void:
	_time += delta

func apply_exposure(delta: float) -> void:
	set_value(value - _loss_rate * delta)

func apply_cost(amount: float) -> void:
	set_value(value - amount)

func recover(delta: float) -> void:
	set_value(minf(maximum, value + _recovery_rate * delta))

func set_value(new_value: float) -> void:
	value = clampf(new_value, 0.0, 1.0)
	if value < _threshold and not _below_threshold:
		_below_threshold = true
		maximum = maxf(0.01, maximum - _max_drop)
		value = minf(value, maximum)
	elif value >= _threshold:
		_below_threshold = false

func reset_state() -> void:
	maximum = float(Data.require_value("shadow.maximum"))
	value = minf(float(Data.require_value("shadow.starting")), maximum)
	_below_threshold = false
	_time = 0.0

func capture_state() -> Dictionary:
	return {
		"value": value,
		"maximum": maximum,
		"below_threshold": _below_threshold,
		"time": _time,
	}

func restore_state(state: Dictionary) -> void:
	value = clampf(float(state.get("value", value)), 0.0, 1.0)
	maximum = clampf(float(state.get("maximum", maximum)), 0.01, 1.0)
	_below_threshold = bool(state.get("below_threshold", _below_threshold))
	_time = float(state.get("time", _time))

func stage() -> String:
	if value <= 0.0:
		return STAGE_GONE
	if value > 0.6:
		return STAGE_NORMAL
	if value > _threshold:
		return STAGE_FLICKERING
	return STAGE_FAINT

func visual_alpha(at_time: float = -1.0) -> float:
	var now := _time if at_time < 0.0 else at_time
	match stage():
		STAGE_FLICKERING:
			return 0.3 + 0.35 * (0.5 + 0.5 * sin(now * _flicker_speed))
		STAGE_FAINT:
			return 0.18
		STAGE_GONE:
			return 0.0
	return 0.8
