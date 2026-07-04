extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load main scene.")
		quit(FAILED)
		return

	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var hud: Node = scene.get_node("HUD")
	var mission_panel := hud.get_node_or_null("Root/MissionPanel") as PanelContainer
	var title_label := hud.get_node_or_null("Root/MissionPanel/Margin/VBox/TitleLabel") as Label
	var objective_label := hud.get_node_or_null("Root/MissionPanel/Margin/VBox/ObjectiveLabel") as Label
	var legacy_label := hud.get_node_or_null("Root/ObjectiveLabel") as Label

	_check(mission_panel != null, "MissionPanel exists.")
	_check(title_label != null, "Mission title label exists.")
	_check(objective_label != null, "Objective label exists inside MissionPanel.")
	_check(legacy_label == null, "Legacy loose ObjectiveLabel was moved out of Root.")

	if mission_panel == null or title_label == null or objective_label == null:
		_finish()
		return

	_check(title_label.text == "MISSION", "Mission title text is stable.")
	_check(objective_label.text == "Talk to the scout.", "Mission objective text is preserved.")
	_check(objective_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "Objective label wraps words.")

	await _check_size(Vector2i(640, 360), 260.0, 310.0, 16, 16)
	await _check_size(Vector2i(1280, 720), 410.0, 450.0, 16, 19)
	await _check_size(Vector2i(2560, 1440), 420.0, 450.0, 19, 20)

	_finish()


func _check_size(viewport_size: Vector2i, min_width: float, max_width: float, min_font: int, max_font: int) -> void:
	root.size = viewport_size
	await process_frame
	var hud: Node = root.get_node("World/HUD")
	hud.call("_on_viewport_resized")
	await process_frame

	var mission_panel := hud.get_node("Root/MissionPanel") as PanelContainer
	var title_label := hud.get_node("Root/MissionPanel/Margin/VBox/TitleLabel") as Label
	var objective_label := hud.get_node("Root/MissionPanel/Margin/VBox/ObjectiveLabel") as Label
	var panel_width: float = mission_panel.offset_right - mission_panel.offset_left
	var objective_font_size: int = objective_label.get_theme_font_size("font_size")
	var title_font_size: int = title_label.get_theme_font_size("font_size")

	_check(panel_width >= min_width and panel_width <= max_width, "MissionPanel width is clamped for %s: %.1f" % [viewport_size, panel_width])
	_check(objective_font_size >= min_font and objective_font_size <= max_font, "Objective font is readable for %s: %d" % [viewport_size, objective_font_size])
	_check(title_font_size >= 12 and title_font_size <= 14, "Mission title font is clamped for %s: %d" % [viewport_size, title_font_size])


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("mission_panel_runtime_ok")
		quit(OK)
	else:
		for failure in _failures:
			push_error(failure)
		quit(FAILED)
