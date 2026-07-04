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
	for _i in range(12):
		await physics_frame

	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var player_animator := scene.get_node_or_null("Player/Animator") as HumanoidLocomotionAnimator
	var player_animation_player := scene.get_node_or_null("Player/SkinPivot/player_robot/AnimationPlayer") as AnimationPlayer
	var player_skeleton := _find_skeleton(scene.get_node_or_null("Player/SkinPivot/player_robot"))
	var npc := scene.get_node_or_null("NPCs/ScoutRobotNPC") as CharacterBody3D
	var npc_animator := scene.get_node_or_null("NPCs/ScoutRobotNPC/Animator") as HumanoidLocomotionAnimator
	var npc_animation_player := scene.get_node_or_null("NPCs/ScoutRobotNPC/SkinPivot/npc_robot/AnimationPlayer") as AnimationPlayer
	var npc_skeleton := _find_skeleton(scene.get_node_or_null("NPCs/ScoutRobotNPC/SkinPivot/npc_robot"))

	if player != null:
		player.set_physics_process(false)
	if npc != null:
		npc.set_physics_process(false)

	_check(player_animator != null, "Player has HumanoidLocomotionAnimator.")
	_check(player_animation_player != null, "Player robot has AnimationPlayer.")
	_check(player_skeleton != null, "Player robot has Skeleton3D.")
	_check(npc_animator != null, "NPC has HumanoidLocomotionAnimator.")
	_check(npc_animation_player != null, "NPC robot has AnimationPlayer.")
	_check(npc_skeleton != null, "NPC robot has Skeleton3D.")

	if player_animator != null and player_animation_player != null:
		await _verify_long_idle("Player", player_animator, player_animation_player, player_skeleton)
	if npc_animator != null and npc_animation_player != null:
		await _verify_long_idle("NPC", npc_animator, npc_animation_player, npc_skeleton)

	if _failures.is_empty():
		print("long_idle_runtime_ok")
		quit(OK)
	else:
		for failure in _failures:
			push_error(failure)
		quit(FAILED)


func _verify_long_idle(label: String, animator: HumanoidLocomotionAnimator, animation_player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	_check(animation_player.has_animation("adventure_locomotion/Idle"), "%s has neutral Idle animation." % label)
	_check(animation_player.has_animation("adventure_locomotion/LongIdle"), "%s has LongIdle animation." % label)
	_check(is_equal_approx(float(animator.get("long_idle_delay")), 10.0), "%s long idle delay is 10 seconds." % label)

	var idle_anim := animation_player.get_animation("adventure_locomotion/Idle")
	var long_idle_anim := animation_player.get_animation("adventure_locomotion/LongIdle")
	if idle_anim != null:
		_check(_matching_tracks_are_frozen(idle_anim, PackedStringArray(["head", "neck"])), "%s short Idle keeps head/neck tracks still." % label)
		_check(_variation_score(idle_anim, PackedStringArray(["head", "neck", "spine", "chest", "shoulder"])) < 0.6, "%s short Idle keeps upper-body motion subtle." % label)
	if long_idle_anim != null:
		_check(long_idle_anim.length > 3.5, "%s LongIdle uses the expressive longer idle clip." % label)
		_check(_variation_score(long_idle_anim, PackedStringArray(["head", "neck"])) > 0.5, "%s LongIdle preserves expressive head/neck motion." % label)

	await _settle_from_movement(animator)

	animator.set_locomotion(0.0, false, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Idle", "%s starts stillness with short Idle." % label)
	if skeleton != null:
		animation_player.advance(0.2)
		await process_frame
		_check(_pose_is_upright_standing(skeleton), "%s short Idle is upright standing, not sitting or crouching." % label)

	for _i in range(9):
		animator.set_locomotion(0.0, false, true, 0.0, 1.0)
		await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Idle", "%s stays in short Idle before 10 seconds." % label)

	animator.set_locomotion(0.0, false, true, 0.0, 1.1)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/LongIdle", "%s switches to LongIdle after 10 seconds." % label)

	animator.set_locomotion(2.0, false, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Walk", "%s exits LongIdle when movement starts." % label)

	animator.set_locomotion(0.0, false, true, 0.0, 0.016)
	await process_frame
	_check(animation_player.current_animation == "adventure_locomotion/Idle", "%s returns to short Idle after movement stops." % label)


func _settle_from_movement(animator: HumanoidLocomotionAnimator) -> void:
	for _i in range(4):
		animator.set_locomotion(2.0, false, true, 0.0, 0.2)
		await process_frame


func _pose_is_upright_standing(skeleton: Skeleton3D) -> bool:
	var hip_y := _bone_y(skeleton, ["hip", "pelvis"])
	var head_y := _bone_y(skeleton, ["head"])
	var left_foot_y := _bone_y(skeleton, ["leftfoot", "left_foot", "mixamorigleftfoot"])
	var right_foot_y := _bone_y(skeleton, ["rightfoot", "right_foot", "mixamorigrightfoot"])
	var foot_y := minf(left_foot_y, right_foot_y)
	return hip_y - foot_y > 1.15 and head_y - foot_y > 1.9


func _bone_y(skeleton: Skeleton3D, filters: Array[String]) -> float:
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_index).to_lower().replace(" ", "").replace("_", "")
		for name_filter in filters:
			if bone_name.contains(name_filter.to_lower().replace(" ", "").replace("_", "")):
				return (skeleton.global_transform * skeleton.get_bone_global_pose(bone_index)).origin.y
	return 0.0


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


func _matching_tracks_are_frozen(anim: Animation, name_filters: PackedStringArray) -> bool:
	var matched_track_count := 0
	for track_index in range(anim.get_track_count()):
		var track_path := str(anim.track_get_path(track_index)).to_lower()
		var matched := false
		for name_filter in name_filters:
			if not name_filter.is_empty() and track_path.contains(name_filter.to_lower()):
				matched = true
				break
		if not matched:
			continue

		matched_track_count += 1
		var key_count := anim.track_get_key_count(track_index)
		if key_count < 2:
			continue

		var first_value: Variant = anim.track_get_key_value(track_index, 0)
		for key_index in range(1, key_count):
			if anim.track_get_key_value(track_index, key_index) != first_value:
				return false

	return matched_track_count > 0


func _variation_score(anim: Animation, name_filters: PackedStringArray) -> float:
	var total := 0.0
	for track_index in range(anim.get_track_count()):
		var track_path := str(anim.track_get_path(track_index)).to_lower()
		var matched := false
		for name_filter in name_filters:
			if not name_filter.is_empty() and track_path.contains(name_filter.to_lower()):
				matched = true
				break
		if not matched:
			continue

		var key_count := anim.track_get_key_count(track_index)
		if key_count < 2:
			continue

		var first_value: Variant = anim.track_get_key_value(track_index, 0)
		var max_delta := 0.0
		for key_index in range(1, key_count):
			max_delta = maxf(max_delta, _value_delta(first_value, anim.track_get_key_value(track_index, key_index)))
		total += max_delta
	return total


func _value_delta(first_value: Variant, value: Variant) -> float:
	if first_value is Quaternion and value is Quaternion:
		return (first_value as Quaternion).angle_to(value as Quaternion)
	if first_value is Vector3 and value is Vector3:
		return (first_value as Vector3).distance_to(value as Vector3)
	if first_value is float and value is float:
		return absf(float(value) - float(first_value))
	return 0.0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append("FAIL: %s" % message)
