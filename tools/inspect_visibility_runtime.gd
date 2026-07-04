extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MAIN_SCENE.instantiate()
	root.add_child(scene)

	await process_frame
	for frame in range(30):
		await physics_frame

	var terrain := scene.get_node_or_null("Level/TerrainRoot") as Node3D
	var terrain_mesh := scene.get_node_or_null("Level/TerrainRoot/TerrainChunk_0_0/GeneratedTerrainMesh") as MeshInstance3D
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	var camera := scene.get_node_or_null("CameraRig/PitchPivot/SpringArm3D/Camera3D") as Camera3D
	var model := scene.get_node_or_null("Player/SkinPivot/player_robot") as Node3D

	if terrain == null or terrain_mesh == null or player == null or camera == null or model == null:
		push_error("Missing runtime node needed for visibility inspection.")
		quit(1)
		return

	var terrain_stats := _terrain_normal_stats(terrain_mesh)
	var player_terrain_height: float = terrain.call("get_height_at", player.global_position.x, player.global_position.z)
	var camera_forward := -camera.global_transform.basis.z.normalized()
	var camera_to_player := player.global_position - camera.global_position
	var look_alignment := camera_forward.dot(camera_to_player.normalized())
	var ray_hit := _raycast(scene, camera.global_position, camera.global_position + camera_forward * 100.0, [])
	var ray_hit_no_player := _raycast(scene, camera.global_position, camera.global_position + camera_forward * 100.0, [player.get_rid()])
	var model_bounds := _global_bounds(model)

	print("terrain_normals avg=", terrain_stats.avg,
		" up_count=", terrain_stats.up_count,
		" down_count=", terrain_stats.down_count)
	print("player_pos=", player.global_position,
		" terrain_y_at_player=", snappedf(player_terrain_height, 0.001),
		" player_delta=", snappedf(player.global_position.y - player_terrain_height, 0.001))
	print("camera_rig_pos=", camera_rig.global_position,
		" camera_pos=", camera.global_position,
		" camera_forward=", camera_forward,
		" camera_to_player_len=", snappedf(camera_to_player.length(), 0.001),
		" look_alignment=", snappedf(look_alignment, 0.001),
		" current=", camera.current)
	print("camera_ray_hit=", _hit_summary(ray_hit))
	print("camera_ray_excluding_player_hit=", _hit_summary(ray_hit_no_player))
	print("player_model_bounds position=", model_bounds.position,
		" size=", model_bounds.size,
		" center=", model_bounds.get_center())

	var failed := false
	if terrain_stats.avg.y < 0.35:
		push_error("Terrain normals are not mostly upward.")
		failed = true
	if look_alignment < 0.75:
		push_error("Camera is not looking toward the player.")
		failed = true
	if model_bounds.size.y > 4.0 or model_bounds.size.x > 3.0 or model_bounds.size.z > 3.0:
		push_error("Player model bounds are unexpectedly large for this camera distance.")
		failed = true

	quit(1 if failed else 0)


func _terrain_normal_stats(terrain_mesh: MeshInstance3D) -> Dictionary:
	var mesh := terrain_mesh.mesh
	var arrays := mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var avg := Vector3.ZERO
	var up_count := 0
	var down_count := 0

	for normal in normals:
		avg += normal
		if normal.y > 0.25:
			up_count += 1
		elif normal.y < -0.25:
			down_count += 1

	if normals.size() > 0:
		avg /= float(normals.size())

	return {
		"avg": avg,
		"up_count": up_count,
		"down_count": down_count,
	}


func _raycast(scene: Node, from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space_state.intersect_ray(query)


func _hit_summary(hit: Dictionary) -> String:
	if hit.is_empty():
		return "none"
	var collider := hit.get("collider") as Node
	var collider_path := "unknown"
	if collider != null:
		collider_path = str(collider.get_path())
	return "%s at %s" % [collider_path, hit.get("position")]


func _global_bounds(root_node: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	var stack: Array[Node] = [root_node]

	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			var local_aabb := mesh_instance.get_aabb()
			var transformed := _transform_aabb(mesh_instance.global_transform, local_aabb)
			if not has_bounds:
				bounds = transformed
				has_bounds = true
			else:
				bounds = bounds.merge(transformed)

	return bounds


func _transform_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var result := AABB()
	var has_point := false

	for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
				var point := transform * Vector3(x, y, z)
				if not has_point:
					result.position = point
					result.size = Vector3.ZERO
					has_point = true
				else:
					result = result.expand(point)

	return result
