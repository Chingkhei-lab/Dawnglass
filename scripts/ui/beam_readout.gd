extends Label

func _physics_process(_delta: float) -> void:
	var beam := get_node_or_null("../../../Lighthouse/Beam")
	if beam == null:
		return
	text = "Beam %d deg   %s   Focus %s   Dawnglass %d%%   Shadow %d%%" % [
		int(rad_to_deg(beam.angle)),
		"MANUAL" if beam.manual_control else "AUTO",
		"ON" if beam.focused else "-",
		int(round(Clock.dawnglass_charge * 100.0)),
		int(round(_shadow_value(beam) * 100.0)),
	]

func _shadow_value(beam: Node) -> float:
	if beam.operator == null:
		return 0.0
	var shadow: Node = beam.operator.get_node_or_null("ShadowComponent")
	return float(shadow.value) if shadow != null else 0.0
