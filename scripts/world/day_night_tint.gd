extends CanvasModulate

func _physics_process(_delta: float) -> void:
	color = Clock.sky_color()
