extends SceneTree


func _init() -> void:
	var err := await _verify()
	quit(err)


func _verify() -> int:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load res://scenes/main.tscn")
		return ERR_CANT_OPEN

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame

	var input_reader := scene.get_node_or_null("InputReader")
	var player := scene.get_node_or_null("Player")
	var camera_rig := scene.get_node_or_null("CameraRig")
	if input_reader == null or player == null or camera_rig == null:
		push_error("Missing InputReader, Player, or CameraRig.")
		return ERR_DOES_NOT_EXIST

	if player.get("input_reader_path") != NodePath("../InputReader"):
		push_error("Player input_reader_path must be ../InputReader.")
		return ERR_INVALID_DATA

	if camera_rig.get("input_reader_path") != NodePath("../InputReader"):
		push_error("CameraRig input_reader_path must be ../InputReader.")
		return ERR_INVALID_DATA

	if not input_reader.has_method("handle_input_event") or not input_reader.has_method("consume_camera_orbit_delta"):
		push_error("InputReader does not expose handle_input_event() and consume_camera_orbit_delta().")
		return ERR_METHOD_NOT_FOUND

	var expected_delta := Vector2(42.0, -18.0)
	input_reader.set("_mouse_delta", expected_delta)

	var first_delta: Vector2 = input_reader.call("consume_camera_orbit_delta")
	var second_delta: Vector2 = input_reader.call("consume_camera_orbit_delta")
	if first_delta != expected_delta:
		push_error("InputReader returned wrong mouse delta: %s" % first_delta)
		return ERR_INVALID_DATA
	if second_delta != Vector2.ZERO:
		push_error("InputReader did not clear mouse delta after consume: %s" % second_delta)
		return ERR_INVALID_DATA

	input_reader.set("_mouse_delta", Vector2(80.0, -30.0))
	var yaw_before: float = camera_rig.rotation.y
	camera_rig.call("_physics_process", 1.0 / 60.0)
	var yaw_after: float = camera_rig.rotation.y
	if is_equal_approx(yaw_before, yaw_after):
		push_error("CameraRig did not rotate after InputReader received mouse delta.")
		return ERR_INVALID_DATA

	print("input_reader_ok delta=%s player_path=%s camera_path=%s yaw_before=%s yaw_after=%s" % [
		first_delta,
		player.get("input_reader_path"),
		camera_rig.get("input_reader_path"),
		snappedf(yaw_before, 0.001),
		snappedf(yaw_after, 0.001),
	])
	return OK
