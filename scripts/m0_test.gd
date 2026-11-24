extends Node

var failures := 0
var frames_remaining := 10800

func _ready() -> void:
	
	print("M0 TEST START")
	if Data.require_value("project.base_width") == 640:
		print("PASS M0 Data loads tuning.json")
	else:
		print("FAIL M0 Data loads tuning.json")
		failures += 1
	var missing = Data.require_value("deliberately_missing.key")
	if missing == null:
		print("PASS M0 missing key produces clear error")
	else:
		print("FAIL M0 missing key unexpectedly resolved")
		failures += 1
	if Engine.physics_ticks_per_second == 60:
		print("PASS M0 physics rate 60 Hz")
	else:
		print("FAIL M0 physics rate expected 60, got %d" % Engine.physics_ticks_per_second)
		failures += 1
	if failures == 0:
		print("M0 TESTS PASS")
	else:
		print("M0 TESTS FAIL (%d failures)" % failures)

func _process(_delta: float) -> void:
	frames_remaining -= 1
	if frames_remaining <= 0:
		get_tree().quit(failures)
