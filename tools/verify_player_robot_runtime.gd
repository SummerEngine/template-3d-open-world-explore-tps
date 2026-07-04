extends SceneTree

const PLAYER_ROBOT_MATERIAL := "res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres"

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
	for _i in range(12):
		await physics_frame

	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var robot := scene.get_node_or_null("Player/SkinPivot/player_robot") as Node3D
	var npc_robot := scene.get_node_or_null("NPCs/ScoutRobotNPC/SkinPivot/npc_robot") as Node3D
	var soldier_on_player := scene.get_node_or_null("Player/SkinPivot/SoldierModel")
	var soldier_on_npc := scene.get_node_or_null("NPCs/ScoutRobotNPC/SkinPivot/SoldierModel")
	var animation_player := scene.get_node_or_null("Player/SkinPivot/player_robot/AnimationPlayer") as AnimationPlayer
	var animator := scene.get_node_or_null("Player/Animator") as HumanoidLocomotionAnimator
	var terrain := scene.get_node_or_null("Level/TerrainRoot")
	var skeleton := _find_skeleton(robot)

	_check(player != null, "Player exists.")
	_check(robot != null, "Player visual node is named player_robot.")
	_check(npc_robot != null, "NPC visual node is named npc_robot.")
	_check(soldier_on_player == null, "Player no longer uses SoldierModel.")
	_check(soldier_on_npc == null, "NPC no longer uses SoldierModel.")
	_check(animation_player != null, "player_robot exposes AnimationPlayer at expected path.")
	_check(animator != null, "Player has HumanoidLocomotionAnimator.")

	if animation_player == null or animator == null:
		_finish()
		return

	for _i in range(40):
		await physics_frame
	if player != null:
		player.set_physics_process(false)

	for state_name in ["Idle", "LongIdle", "Walk", "Run", "Jump", "Fall", "Land"]:
		_check(animation_player.has_animation("adventure_locomotion/%s" % state_name), "Neutral state exists: %s." % state_name)

	animator.set_locomotion(0.0, false, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Idle", "Idle state plays from neutral library.")

	animator.set_locomotion(2.0, false, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Walk", "Walk state plays from neutral library.")

	animator.set_locomotion(7.0, true, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Run", "Run state plays from neutral library.")

	animator.set_locomotion(0.0, false, false, 4.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Jump", "Jump state plays from neutral library.")

	animator.set_locomotion(0.0, false, false, -4.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Fall", "Fall state plays from neutral library.")

	var bounds := _global_bounds(robot)
	_check(bounds.size.y > 0.8 and bounds.size.y < 3.2, "player_robot visual bounds are plausible.")
	_check(load(PLAYER_ROBOT_MATERIAL) != null, "player_robot material resource loads.")
	_check(_has_material_override(robot, PLAYER_ROBOT_MATERIAL), "player_robot material is applied to imported meshes.")
	_check(_has_material_override(npc_robot, PLAYER_ROBOT_MATERIAL), "npc_robot material is applied to imported meshes.")
	if terrain != null and player != null:
		var terrain_y: float = terrain.call("get_height_at_global", player.global_position.x, player.global_position.z)
		animation_player.play("adventure_locomotion/Idle")
		animation_player.advance(0.2)
		await process_frame
		var idle_foot_y := _lowest_foot_bone_y(skeleton)
		_check(absf(idle_foot_y - terrain_y) <= 0.08, "player_robot idle feet touch the sampled terrain.")

		animation_player.play("adventure_locomotion/Walk")
		animation_player.advance(0.2)
		await process_frame
		var walk_foot_y := _lowest_foot_bone_y(skeleton)
		_check(absf(walk_foot_y - terrain_y) <= 0.10, "player_robot walk feet touch the sampled terrain.")

	_finish()


func _find_skeleton(root_node: Node) -> Skeleton3D:
	if root_node == null:
		return null
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


func _has_material_override(root_node: Node, material_path: String) -> bool:
	if root_node == null:
		return false

	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not node is MeshInstance3D:
			continue

		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.get_surface_override_material(surface_index)
			if surface_material != null and surface_material.resource_path == material_path:
				return true

	return false


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


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		var failure := "FAIL: %s" % message
		_failures.append(failure)
		push_error(failure)


func _finish() -> void:
	if _failures.is_empty():
		print("player_robot_runtime_ok")
	quit(OK if _failures.is_empty() else FAILED)
