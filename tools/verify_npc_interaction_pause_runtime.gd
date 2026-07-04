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

	var player := scene.get_node_or_null("Player") as Node3D
	var npc := scene.get_node_or_null("NPCs/ScoutRobotNPC") as CharacterBody3D
	var quest_area := scene.get_node_or_null("NPCs/ScoutRobotNPC/QuestGiverArea")

	_check(player != null, "Player exists.")
	_check(npc != null, "ScoutRobotNPC exists.")
	_check(quest_area != null, "QuestGiverArea exists.")
	if player == null or npc == null or quest_area == null:
		_finish()
		return

	_check(npc.has_method("on_interacted_by"), "ScoutRobotNPC exposes interaction pause hook.")
	_check(npc.has_method("is_addressing_player"), "ScoutRobotNPC exposes address-pause status.")

	quest_area.call("interact", player)
	var remaining := float(npc.call("get_address_pause_remaining"))
	var velocity_flat := Vector3(npc.velocity.x, 0.0, npc.velocity.z)
	var desired_facing := player.global_position - npc.global_position
	desired_facing.y = 0.0
	desired_facing = desired_facing.normalized()
	var actual_facing := npc.call("get_current_facing") as Vector3

	_check(bool(npc.call("is_addressing_player")), "NPC is addressing the player after interaction.")
	_check(remaining >= 2.0 and remaining <= 3.0, "NPC address pause is between 2 and 3 seconds.")
	_check(int(npc.call("get_current_state")) == 0, "NPC enters IDLE while addressing the player.")
	_check(velocity_flat.length() <= 0.001, "NPC horizontal movement stops during address pause.")
	_check(actual_facing.dot(desired_facing) >= 0.9, "NPC turns to face the player during address pause.")

	for _i in range(70):
		await physics_frame
	_check(bool(npc.call("is_addressing_player")), "NPC is still addressing after roughly one second.")

	for _i in range(160):
		await physics_frame
	_check(not bool(npc.call("is_addressing_player")), "NPC address pause releases after the 2-3 second window.")

	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("NPC interaction pause runtime verification passed.")
		quit(OK)
	else:
		for failure in _failures:
			push_error(failure)
		quit(FAILED)
