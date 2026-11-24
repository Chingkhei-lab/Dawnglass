extends Node

const KEY_CODE := KEY_TAB
const PAD_BUTTON := JOY_BUTTON_Y

@export var camera_path: NodePath = ^"../Camera2D"
@export var keeper_paths: Array[NodePath] = []

var _index := 0

func _ready() -> void:
	add_to_group("keeper_switcher")
	_bind_switch()
	var keepers := _keepers()
	for index in range(keepers.size()):
		keepers[index].controlled = index == _index
	if not keepers.is_empty():
		_focus(keepers[_index])

func _physics_process(_delta: float) -> void:
	if _input_blocked():
		return
	if Input.is_action_just_pressed("switch_keeper"):
		switch_next()

func switch_next() -> void:
	var keepers := _keepers()
	if keepers.size() < 2:
		return
	select_keeper(keepers[(_index + 1) % keepers.size()])

func select_keeper(keeper: Node) -> bool:
	var keepers := _keepers()
	var next_index := keepers.find(keeper)
	if next_index < 0:
		return false
	if _index < keepers.size():
		keepers[_index].velocity = Vector2.ZERO
	_index = next_index
	for index in range(keepers.size()):
		keepers[index].controlled = index == _index
	_focus(keepers[_index])
	Events.keeper_switched.emit()
	return true

func active_keeper() -> Node:
	var keepers := _keepers()
	if keepers.is_empty():
		return null
	return keepers[_index]

func _focus(keeper: Node) -> void:
	var camera := get_node_or_null(camera_path)
	if camera != null and camera.has_method("set_target"):
		camera.set_target(keeper)

func _keepers() -> Array:
	var result := []
	for path in keeper_paths:
		var keeper := get_node_or_null(path)
		if keeper != null:
			result.append(keeper)
	return result

func _input_blocked() -> bool:
	var dialogue := get_tree().get_first_node_in_group("dialogue_boxes")
	if dialogue != null and dialogue.is_open():
		return true
	var summary := get_tree().get_first_node_in_group("dawn_summary")
	return summary != null and summary.visible

func _bind_switch() -> void:
	if not InputMap.has_action("switch_keeper"):
		InputMap.add_action("switch_keeper")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_CODE
	_add_event_once("switch_keeper", key)
	var button := InputEventJoypadButton.new()
	button.button_index = PAD_BUTTON
	_add_event_once("switch_keeper", button)

func _add_event_once(action: String, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == event.as_text():
			return
	InputMap.action_add_event(action, event)
