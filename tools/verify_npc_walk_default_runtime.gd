extends SceneTree


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

	var npc: Node = scene.get_node_or_null("NPCs/ScoutRobotNPC")
	if npc == null:
		push_error("Missing ScoutRobotNPC.")
		quit(FAILED)
		return

	if bool(npc.get("allow_running")):
		push_error("ScoutRobotNPC should have allow_running disabled by default.")
		quit(FAILED)
		return

	var travel_state: int = int(npc.call("_travel_state_to_current_target"))
	if travel_state != 1:
		push_error("ScoutRobotNPC default travel state should be WALK, got enum value %d." % travel_state)
		quit(FAILED)
		return

	print("npc_walk_default_ok allow_running=false travel_state=WALK")
	quit(OK)
