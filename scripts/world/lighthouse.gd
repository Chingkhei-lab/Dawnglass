extends Node2D

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(Data.require_value("beam.lamp_room_radius"))
	shape.shape = circle
	$LampRoom.add_child(shape)
