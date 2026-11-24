extends Node

const TUNING_PATH := "res://data/tuning.json"
var tuning: Dictionary = {}

func _ready() -> void:
	load_tuning()

func load_tuning() -> void:
	if not FileAccess.file_exists(TUNING_PATH):
		push_error("Data: missing tuning file: %s" % TUNING_PATH)
		return
	var file := FileAccess.open(TUNING_PATH, FileAccess.READ)
	if file == null:
		push_error("Data: could not open tuning file: %s" % TUNING_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Data: tuning JSON root must be an object")
		return
	tuning = parsed

func require_value(path: String):
	var value = tuning
	for part in path.split("."):
		if not value is Dictionary or not value.has(part):
			print("Data: missing required tuning key: %s" % path)
			return null
		value = value[part]
	return value
