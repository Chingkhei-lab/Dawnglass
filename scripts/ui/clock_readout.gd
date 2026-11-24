extends Label

func _physics_process(_delta: float) -> void:
	text = "Day %d   %s   %.1f / %.0f s   Dawnglass %d%%" % [
		Clock.day,
		Clock.phase.to_upper(),
		Clock.phase_elapsed,
		Clock.phase_length(),
		roundi(Clock.dawnglass_charge * 100.0),
	]
