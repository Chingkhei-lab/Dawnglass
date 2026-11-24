extends Node2D

const RUNTIME_FRAMES := 10800

var failures := 0
var step := 0
var step_frame := 0
var runtime_left := RUNTIME_FRAMES
var start_x := 0.0
var camera_start_distance := 0.0

@onready var keeper: CharacterBody2D = $Keeper
@onready var house: StaticBody2D = $House
@onready var sign_node: Area2D = $Sign
@onready var text_box: CanvasLayer = $TextBox
@onready var follow_camera: Camera2D = $Camera2D

func _ready() -> void:
	keeper.interacted.connect(text_box.show_text)
	print("M1 TEST START")
	_check_structure()

func _physics_process(_delta: float) -> void:
	if step >= 7:
		_runtime_tick()
		return
	step_frame += 1
	match step:
		0:
			if step_frame >= 4:
				_advance(1)
		1:
			_movement_step()
		2:
			_collision_step()
		3:
			_corner_step()
		4:
			_interaction_step()
		5:
			_camera_step()
		6:
			_finish_tests()

func _check_structure() -> void:
	_expect(y_sort_enabled, "PASS M1 area y-sort enabled", "FAIL M1 area y-sort disabled")
	_expect(house.get_parent() == self and keeper.get_parent() == self, "PASS M1 house and keeper share y-sorted parent", "FAIL M1 house and keeper are not y-sort siblings")
	_expect(house.z_index == 0 and keeper.z_index == 0, "PASS M1 no z_index overrides y-sort", "FAIL M1 z_index overrides y-sort")
	_expect(_polygon_base_offset(house) <= 0.01, "PASS M1 house sorts from its base", "FAIL M1 house sort anchor is not its base")
	_expect(text_box.is_open() == false, "PASS M1 text box starts hidden", "FAIL M1 text box starts visible")
	_expect(InputMap.has_action("move_left") and InputMap.has_action("move_right"), "PASS M1 keyboard/gamepad movement actions registered", "FAIL M1 movement actions missing")
	_expect(InputMap.has_action("interact") and InputMap.action_get_events("interact").size() >= 2, "PASS M1 interact action has keyboard and gamepad bindings", "FAIL M1 interact bindings incomplete")

func _polygon_base_offset(body: Node) -> float:
	var polygon_node := body.get_node_or_null("Body")
	if polygon_node == null:
		return INF
	var highest := -INF
	for point in polygon_node.polygon:
		highest = max(highest, point.y)
	return abs(highest)

func _movement_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(300, 320)
		start_x = keeper.position.x
		Input.action_press("move_right")
	elif step_frame == 25:
		Input.action_release("move_right")
	elif step_frame == 30:
		var moved := keeper.position.x - start_x
		_expect(moved > 8.0, "PASS M1 movement via input action (%.1f px)" % moved, "FAIL M1 movement: moved %.1f px" % moved)
		_advance(2)

func _collision_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(480, 220)
		Input.action_press("move_right")
	elif step_frame == 55:
		Input.action_release("move_right")
	elif step_frame == 60:
		var x := keeper.position.x
		var blocked := x <= 504.0 and x >= 490.0
		_expect(blocked, "PASS M1 house collision blocks keeper at x=%.1f" % x, "FAIL M1 house collision: keeper at x=%.1f" % x)
		_advance(3)

func _corner_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(490, 292)
		Input.action_press("move_up")
		Input.action_press("move_right")
	elif step_frame == 90:
		Input.action_release("move_up")
		Input.action_release("move_right")
		var x := keeper.position.x
		var top := keeper.position.y - 16.0
		var slid := x > 530.0 and top >= 259.0
		_expect(slid, "PASS M1 corner slide (x=%.1f, top=%.1f)" % [x, top], "FAIL M1 stuck on corner (x=%.1f, top=%.1f)" % [x, top])
		Input.action_press("move_down")
	elif step_frame == 120:
		Input.action_release("move_down")
		var left_corner := keeper.position.y > 292.0
		_expect(left_corner, "PASS M1 keeper leaves corner freely", "FAIL M1 keeper cannot leave corner")
		_advance(4)

func _interaction_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(392, 362)
	elif step_frame == 6:
		var success: bool = keeper.try_interact()
		_expect(success, "PASS M1 interaction detects sign", "FAIL M1 sign not detected")
	elif step_frame == 8:
		var sign_text: String = sign_node.interaction_text
		var box_text: String = text_box.shown_text()
		var shown: bool = text_box.is_open() and box_text == sign_text and box_text.length() > 0
		_expect(shown, "PASS M1 sign interaction shows text box", "FAIL M1 text box did not show sign text")
		_advance(5)

func _camera_step() -> void:
	if step_frame == 1:
		keeper.position = Vector2(200, 200)
		camera_start_distance = follow_camera.global_position.distance_to(keeper.global_position)
	elif step_frame == 15:
		var distance := follow_camera.global_position.distance_to(keeper.global_position)
		var approaching := distance < camera_start_distance - 5.0 and distance > 1.0
		_expect(approaching, "PASS M1 camera follows smoothly (%.1f -> %.1f px)" % [camera_start_distance, distance], "FAIL M1 camera follow: %.1f -> %.1f px" % [camera_start_distance, distance])
	elif step_frame == 150:
		var distance := follow_camera.global_position.distance_to(keeper.global_position)
		_expect(distance < 3.0, "PASS M1 camera settles on keeper (%.2f px)" % distance, "FAIL M1 camera did not settle (%.2f px)" % distance)
		var behind := keeper.position.y < house.position.y
		_expect(behind and house.position.y - keeper.position.y > 10.0, "PASS M1 keeper above house sorts behind (y %.1f < %.1f)" % [keeper.position.y, house.position.y], "FAIL M1 y-sort relation wrong")
		_advance(6)

func _finish_tests() -> void:
	if failures == 0:
		print("M1 TESTS PASS")
	else:
		print("M1 TESTS FAIL (%d failures)" % failures)
	if _fast_mode():
		get_tree().quit(failures)
		return
	print("M1 RUNTIME CHECK START")
	step = 7

func _runtime_tick() -> void:
	runtime_left -= 1
	if runtime_left <= 0:
		print("M1 RUNTIME CHECK COMPLETE")
		get_tree().quit(failures)

func _fast_mode() -> bool:
	return OS.get_cmdline_args().has("--fast") or OS.get_cmdline_user_args().has("--fast")

func _advance(next_step: int) -> void:
	step = next_step
	step_frame = 0

func _expect(condition: bool, pass_text: String, fail_text: String) -> void:
	if condition:
		print(pass_text)
	else:
		print(fail_text)
		failures += 1
