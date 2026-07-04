extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	for _i in range(12):
		await physics_frame

	var player := scene.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	var robot := scene.get_node("Player/SkinPivot/player_robot") as Node3D
	var animation_player := scene.get_node("Player/SkinPivot/player_robot/AnimationPlayer") as AnimationPlayer
	var terrain := scene.get_node("Level/TerrainRoot")
	var terrain_y: float = terrain.call("get_height_at_global", player.global_position.x, player.global_position.z)
	var skeleton := _find_skeleton(robot)

	print("robot_position_y=", robot.position.y, " terrain_y=", terrain_y)
	for animation_name in ["adventure_locomotion/Idle", "adventure_locomotion/Walk", "adventure_locomotion/Run"]:
		animation_player.play(animation_name)
		await process_frame
		animation_player.advance(0.2)
		await process_frame
		var bounds := _global_bounds(robot)
		var foot_y := _lowest_foot_bone_y(skeleton)
		print("%s bounds_min_y=%.4f foot_bone_min_y=%.4f terrain_delta_bounds=%.4f terrain_delta_foot=%.4f" % [
			animation_name,
			bounds.position.y,
			foot_y,
			bounds.position.y - terrain_y,
			foot_y - terrain_y,
		])

	quit(OK)


func _find_skeleton(root_node: Node) -> Skeleton3D:
	if root_node is Skeleton3D:
		return root_node
	for child in root_node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _lowest_foot_bone_y(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return INF
	var lowest := INF
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_index).to_lower()
		if not ("foot" in bone_name or "toe" in bone_name):
			continue
		var global_pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone_index)
		lowest = minf(lowest, global_pose.origin.y)
	return lowest


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
			var transformed := _transform_aabb(mesh_instance.global_transform, mesh_instance.get_aabb())
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
