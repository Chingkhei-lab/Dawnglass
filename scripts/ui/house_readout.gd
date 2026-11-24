extends Label

const PEOPLE := ["odile", "vell", "ferrow"]

func _physics_process(_delta: float) -> void:
	var states := PackedStringArray()
	for person in PEOPLE:
		states.append("%s %s" % [person.to_upper(), String(GameState.houses.get(person, "home")).to_upper()])
	text = "Day %d  %s  %s" % [Clock.day, Clock.phase.to_upper(), "  ".join(states)]
