extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MAIN_SCENE.instantiate()
	root.add_child(scene)

	await process_frame
	await physics_frame

	var terrain := scene.get_node_or_null("Level/TerrainRoot") as Node3D
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	if terrain == null or player == null:
		push_error("Missing TerrainRoot or Player in main scene.")
		quit(1)
		return

	var collision_bodies := _find_nodes_named(terrain, "GeneratedTerrainBody")
	var terrain_meshes := _find_nodes_named(terrain, "GeneratedTerrainMesh")
	if collision_bodies.size() != 9 or terrain_meshes.size() != 9:
		push_error("Terrain grid should generate 9 meshes and 9 collision bodies. meshes=%d bodies=%d" % [terrain_meshes.size(), collision_bodies.size()])
		quit(1)
		return
	if terrain.has_method("get_active_chunk_count") and int(terrain.call("get_active_chunk_count")) != 9:
		push_error("Terrain grid active chunk count should be 9.")
		quit(1)
		return
	if terrain.has_method("get_active_chunk_coords"):
		print("initial_chunks=", terrain.call("get_active_chunk_coords"))

	var stats := _sample_terrain(terrain)
	print("terrain_min=", snappedf(stats.min_height, 0.001),
		" terrain_max=", snappedf(stats.max_height, 0.001),
		" max_adjacent_delta=", snappedf(stats.max_adjacent_delta, 0.001))

	for frame in range(180):
		await physics_frame
		if player.global_position.y < -8.0:
			push_error("Player fell below the terrain test floor at frame %d, y=%s." % [frame, player.global_position.y])
			quit(1)
			return

	var expected_height: float = terrain.call("get_height_at", player.global_position.x, player.global_position.z)
	var delta: float = player.global_position.y - expected_height
	print("player_y=", snappedf(player.global_position.y, 0.001),
		" terrain_y=", snappedf(expected_height, 0.001),
		" delta=", snappedf(delta, 0.001),
		" is_on_floor=", player.is_on_floor())

	if delta < -0.1 or delta > 1.0:
		push_error("Player did not settle on terrain. Height delta was %s." % delta)
		quit(1)
		return

	player.global_position = Vector3(80.0, player.global_position.y, 12.0)
	terrain.call("_physics_process", 1.0 / 60.0)
	var shifted_count := int(terrain.call("get_active_chunk_count")) if terrain.has_method("get_active_chunk_count") else 0
	var shifted_coords: Array = terrain.call("get_active_chunk_coords") if terrain.has_method("get_active_chunk_coords") else []
	print("shifted_chunks=", shifted_coords)
	if shifted_count != 9 or not shifted_coords.has(Vector2i(1, 0)):
		push_error("Terrain grid did not recenter to the player's new chunk. count=%d coords=%s" % [shifted_count, shifted_coords])
		quit(1)
		return

	quit(0)


func _sample_terrain(terrain: Node) -> Dictionary:
	var min_height := INF
	var max_height := -INF
	var max_adjacent_delta := 0.0
	var previous_row: Array[float] = []
	var step := 4.0
	var half := 36.0
	var row_index := 0

	for z_i in range(19):
		var z := -half + float(z_i) * step
		var row: Array[float] = []
		for x_i in range(19):
			var x := -half + float(x_i) * step
			var h: float = terrain.call("get_height_at", x, z)
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)
			if x_i > 0:
				max_adjacent_delta = maxf(max_adjacent_delta, absf(h - row[x_i - 1]))
			if row_index > 0:
				max_adjacent_delta = maxf(max_adjacent_delta, absf(h - previous_row[x_i]))
			row.append(h)
		previous_row = row
		row_index += 1

	return {
		"min_height": min_height,
		"max_height": max_height,
		"max_adjacent_delta": max_adjacent_delta,
	}


func _find_nodes_named(root_node: Node, node_name: String) -> Array[Node]:
	var found: Array[Node] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == node_name:
			found.append(node)
		for child in node.get_children():
			stack.append(child)
	return found
