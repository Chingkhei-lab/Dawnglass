extends "res://scripts/creatures/creature_base.gd"

var target: Node = null

func _behave(delta: float) -> void:
	target = _nearest_person()
	if target == null:
		return
	_move_toward(target.global_position, float(Data.require_value("creatures.walker_speed")), delta)
