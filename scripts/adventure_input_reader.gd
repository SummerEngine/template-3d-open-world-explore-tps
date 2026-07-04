extends Node
class_name AdventureInputReader

@export var capture_mouse_on_ready: bool = true
@export var recapture_on_mouse_button: bool = true
@export var ensure_input_actions: bool = true

var _mouse_delta: Vector2 = Vector2.ZERO


func _ready() -> void:
	if ensure_input_actions:
		ensure_default_actions()

	if capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	handle_input_event(event)


func handle_input_event(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var delta := motion.screen_relative
		if delta == Vector2.ZERO:
			delta = motion.relative
		_mouse_delta += delta
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and recapture_on_mouse_button and not _is_wheel_button(mouse_event.button_index):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_movement_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func get_camera_axis() -> Vector2:
	return Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")


func consume_camera_orbit_delta() -> Vector2:
	var value := _mouse_delta
	_mouse_delta = Vector2.ZERO
	return value


func is_sprint_pressed() -> bool:
	return Input.is_action_pressed(&"sprint")


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"jump")


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"interact")


func is_inventory_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"inventory")


static func ensure_default_actions() -> void:
	for action_name in _required_actions():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.5)
		if InputMap.action_get_events(action_name).is_empty():
			_add_default_event(action_name)


static func _required_actions() -> Array[StringName]:
	return [
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_back",
		&"jump",
		&"sprint",
		&"interact",
		&"inventory",
		&"camera_left",
		&"camera_right",
		&"camera_up",
		&"camera_down",
		&"ui_cancel",
	]


static func _add_default_event(action_name: StringName) -> void:
	match action_name:
		&"move_left":
			_add_key_event(action_name, KEY_A)
		&"move_right":
			_add_key_event(action_name, KEY_D)
		&"move_forward":
			_add_key_event(action_name, KEY_W)
		&"move_back":
			_add_key_event(action_name, KEY_S)
		&"jump":
			_add_key_event(action_name, KEY_SPACE)
		&"sprint":
			_add_key_event(action_name, KEY_SHIFT)
		&"interact":
			_add_key_event(action_name, KEY_E)
		&"inventory":
			_add_key_event(action_name, KEY_I)
		&"camera_left":
			_add_joy_axis_event(action_name, JOY_AXIS_RIGHT_X, -1.0)
		&"camera_right":
			_add_joy_axis_event(action_name, JOY_AXIS_RIGHT_X, 1.0)
		&"camera_up":
			_add_joy_axis_event(action_name, JOY_AXIS_RIGHT_Y, -1.0)
		&"camera_down":
			_add_joy_axis_event(action_name, JOY_AXIS_RIGHT_Y, 1.0)
		&"ui_cancel":
			_add_key_event(action_name, KEY_ESCAPE)


static func _add_key_event(action_name: StringName, keycode: int) -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = keycode as Key
	InputMap.action_add_event(action_name, key_event)


static func _add_joy_axis_event(action_name: StringName, axis: int, axis_value: float) -> void:
	var axis_event := InputEventJoypadMotion.new()
	axis_event.axis = axis as JoyAxis
	axis_event.axis_value = axis_value
	InputMap.action_add_event(action_name, axis_event)


static func _is_wheel_button(button_index: int) -> bool:
	return button_index == MOUSE_BUTTON_WHEEL_UP or button_index == MOUSE_BUTTON_WHEEL_DOWN
