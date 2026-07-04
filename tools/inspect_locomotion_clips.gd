extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MAIN_SCENE.instantiate()
	root.add_child(scene)

	await process_frame
	for frame in range(20):
		await process_frame

	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var animator := scene.get_node_or_null("Player/Animator") as HumanoidLocomotionAnimator
	var animation_player := scene.get_node_or_null("Player/SkinPivot/player_robot/AnimationPlayer") as AnimationPlayer
	var model := scene.get_node_or_null("Player/SkinPivot/player_robot") as Node3D
	var terrain := scene.get_node_or_null("Level/TerrainRoot") as Node3D

	if player == null or animator == null or animation_player == null or model == null or terrain == null:
		push_error("Missing player, animator, model, or terrain.")
		quit(1)
		return

	var terrain_y: float = terrain.call("get_height_at", player.global_position.x, player.global_position.z)
	print("player_y=", snappedf(player.global_position.y, 0.001),
		" terrain_y=", snappedf(terrain_y, 0.001),
		" player_delta=", snappedf(player.global_position.y - terrain_y, 0.001))
	_print_root_track("Idle", animation_player)
	_print_root_track("Walk", animation_player)
	_print_root_track("Run", animation_player)
	_print_root_track("Jump", animation_player)
	_print_root_track("Fall", animation_player)
	_print_root_track("Land", animation_player)

	await _sample_state("Idle", animator, model, 0.0, false)
	await _sample_state("Walk", animator, model, 2.0, false)
	await _sample_state("Run", animator, model, 7.0, true)

	quit(0)


func _print_root_track(label: String, animation_player: AnimationPlayer) -> void:
	var animation_path := "adventure_locomotion/%s" % label
	if not animation_player.has_animation(animation_path):
		print(label, " imported_root_track=missing")
		return
	var anim := animation_player.get_animation(animation_path)
	for track_index in range(anim.get_track_count()):
		var path := str(anim.track_get_path(track_index)).to_lower()
		if not path.contains("hips"):
			continue
		if anim.track_get_key_count(track_index) == 0:
			continue
		var first: Variant = anim.track_get_key_value(track_index, 0)
		var mid: Variant = anim.track_get_key_value(track_index, anim.track_get_key_count(track_index) / 2)
		var last: Variant = anim.track_get_key_value(track_index, anim.track_get_key_count(track_index) - 1)
		if first is Vector3:
			print(label, " imported_hips first=", first, " mid=", mid, " last=", last)
			return
	print(label, " imported_root_track=not_found")


func _sample_state(label: String, animator: HumanoidLocomotionAnimator, model: Node3D, speed: float, sprinting: bool) -> void:
	var min_y := INF
	var max_y := -INF
	var smallest_bounds := AABB()
	var largest_bounds := AABB()

	for frame in range(90):
		animator.set_locomotion(speed, sprinting, true, 0.0)
		await process_frame
		var bounds := _global_bounds(model)
		if bounds.position.y < min_y:
			min_y = bounds.position.y
			smallest_bounds = bounds
		if bounds.position.y + bounds.size.y > max_y:
			max_y = bounds.position.y + bounds.size.y
			largest_bounds = bounds

	print(label,
		" visual_min_y=", snappedf(min_y, 0.001),
		" visual_max_y=", snappedf(max_y, 0.001),
		" lowest_bounds_pos=", smallest_bounds.position,
		" lowest_bounds_size=", smallest_bounds.size,
		" highest_bounds_pos=", largest_bounds.position,
		" highest_bounds_size=", largest_bounds.size)


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
