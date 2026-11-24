extends CanvasLayer

@onready var panel: ColorRect = $Panel
@onready var label: Label = $Panel/Label

func _ready() -> void:
	hide_text()

func show_text(text: String) -> void:
	label.text = text
	panel.visible = true

func hide_text() -> void:
	panel.visible = false

func is_open() -> bool:
	return panel.visible

func shown_text() -> String:
	return label.text
