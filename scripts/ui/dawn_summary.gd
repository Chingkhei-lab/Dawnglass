extends Control

signal dismissed

var last_report: Dictionary = {}
var _pending := false

@onready var report_label: Label = $Panel/Report
@onready var hint_label: Label = $Panel/Hint

func _ready() -> void:
	add_to_group("dawn_summary")
	visible = false
	Events.dawn.connect(_on_dawn)
	Events.day_started.connect(_on_day_started)
	Events.state_loaded.connect(_on_state_loaded)
	_on_state_loaded()

func dismiss() -> void:
	visible = false
	dismissed.emit()

func _on_dawn() -> void:
	if _pending:
		return
	_pending = true
	call_deferred("_finalize")

func _finalize() -> void:
	_pending = false
	var stats := get_tree().get_first_node_in_group("night_stats")
	if stats == null:
		return
	last_report = stats.finalize()
	GameState.last_dawn = last_report.duplicate(true)
	_show_report(last_report)

func _on_day_started() -> void:
	visible = false

func _on_state_loaded() -> void:
	var report := GameState.last_dawn
	var matches_day := int(report.get("day", 0)) == Clock.day
	if not report.is_empty() and matches_day and (Clock.phase == Clock.PHASE_DAY or Clock.phase == Clock.PHASE_DAWN):
		last_report = report.duplicate(true)
		_show_report(last_report)

func _show_report(report: Dictionary) -> void:
	var safe: Array = report.get("safe", [])
	var asleep: Array = report.get("sleepers", [])
	report_label.text = "DAWN — DAY %d\n\nSAFE\n%s\n\nASLEEP\n%s\n\nPROMISES  %d KEPT · %d BROKEN\nCREATURES DESTROYED  %d" % [
		int(report.get("day", Clock.day)),
		_list_text(safe),
		_list_text(asleep),
		int(report.get("promises_kept", 0)),
		int(report.get("promises_broken", 0)),
		int(report.get("creatures_destroyed", 0)),
	]
	hint_label.text = "E  CLOSE"
	visible = true

func _list_text(values: Array) -> String:
	if values.is_empty():
		return "Nobody"
	return " · ".join(values)
