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
	for _i in range(8):
		await physics_frame

	var terrain := scene.get_node_or_null("Level/TerrainRoot")
	var features := scene.get_node_or_null("Level/TerrainRoot/Features")
	var scout_pad := scene.get_node_or_null("Level/TerrainRoot/Features/ScoutCampFlatPad")
	var relic_pad := scene.get_node_or_null("Level/TerrainRoot/Features/RelicClearingFlatPad")
	var homestead_pad := scene.get_node_or_null("Level/TerrainRoot/Features/StarterHomesteadFlatPad")
	var road := scene.get_node_or_null("Level/TerrainRoot/Features/PlayerScoutRelicRoad")

	_check(terrain != null, "TerrainRoot exists.")
	_check(features != null, "Terrain feature root exists.")
	_check(scout_pad != null and scout_pad.has_method("get_terrain_feature_data"), "Scout flat pad exists and exports feature data.")
	_check(relic_pad != null and relic_pad.has_method("get_terrain_feature_data"), "Relic flat pad exists and exports feature data.")
	_check(homestead_pad != null and homestead_pad.has_method("get_terrain_feature_data"), "Starter homestead flat pad exists and exports feature data.")
	_check(road == null, "Default road path has been removed.")
	_check(_first_named(scene, "FlatPadPreview") == null, "Flat pad preview plane meshes are absent.")
	_check(_first_named(scene, "RoadPreview") == null, "Road preview plane meshes are absent.")

	if terrain == null:
		_finish()
		return

	var scout_range := _height_range(terrain, Vector2(10.0, -8.0), Vector2(3.5, 2.5))
	var homestead_range := _height_range(terrain, Vector2(-13.0, 14.0), Vector2(14.0, 10.0))
	var off_pad_height_a: float = terrain.call("get_height_at_global", 24.0, 24.0)
	var off_pad_height_b: float = terrain.call("get_height_at_global", 30.0, 24.0)

	_check(scout_range <= 0.08, "Scout flat pad has a low height range for structure placement. range=%s" % snappedf(scout_range, 0.001))
	_check(homestead_range <= 0.08, "Expanded starter homestead flat pad has a low height range for doubled buildings. range=%s" % snappedf(homestead_range, 0.001))
	_check(absf(off_pad_height_a - off_pad_height_b) > 0.02, "Non-pad terrain still keeps natural height variation.")

	if _failures.is_empty():
		print("terrain_features_runtime_ok scout_range=", snappedf(scout_range, 0.001),
			" homestead_range=", snappedf(homestead_range, 0.001))
	quit(OK if _failures.is_empty() else FAILED)


func _height_range(terrain: Node, center: Vector2, half_extents: Vector2) -> float:
	var min_height := INF
	var max_height := -INF
	for x_index in range(4):
		for z_index in range(4):
			var x := center.x + lerpf(-half_extents.x, half_extents.x, float(x_index) / 3.0)
			var z := center.y + lerpf(-half_extents.y, half_extents.y, float(z_index) / 3.0)
			var h: float = terrain.call("get_height_at_global", x, z)
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)
	return max_height - min_height


func _first_named(root_node: Node, node_name: StringName) -> Node:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == node_name:
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		var failure := "FAIL: %s" % message
		_failures.append(failure)
		push_error(failure)


func _finish() -> void:
	quit(OK if _failures.is_empty() else FAILED)
