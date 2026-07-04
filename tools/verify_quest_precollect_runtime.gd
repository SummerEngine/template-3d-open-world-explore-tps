extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load res://scenes/main.tscn.")
		quit(FAILED)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	for _i in range(4):
		await physics_frame

	var player: Node = scene.get_node("Player")
	var hud: Node = scene.get_node("HUD")
	var inventory: Node = scene.get_node("Inventory")
	var quest: Node = scene.get_node("QuestState")
	var npc_area: Node = scene.get_node("NPCs/ScoutRobotNPC/QuestGiverArea")
	var relic: Node = scene.get_node("Level/Collectibles/Relic")

	_check(int(quest.get("step")) == 0, "Quest starts at TALK_TO_SCOUT.")

	relic.call("interact", player)
	await process_frame

	_check(bool(inventory.call("has_item", &"forest_relic")), "Pre-collected relic is stored in inventory.")
	_check(bool(relic.get("collected_once")), "Relic marks itself collected.")
	_check(int(quest.get("step")) == 0, "Pre-collecting before scout does not incorrectly assign the quest.")

	npc_area.call("interact", player)
	await process_frame

	_check(int(quest.get("step")) == 3, "Scout completes quest when relic was already collected.")
	_check(_objective_text(hud) == "Objective complete.", "HUD objective completes after scout recognizes pre-collected relic.")

	var count_before := int(inventory.call("get_item_count"))
	relic.call("interact", player)
	await process_frame
	_check(int(inventory.call("get_item_count")) == count_before, "Relic cannot be duplicated after pre-collect completion.")

	if _failures.is_empty():
		print("Quest precollect runtime verification passed.")
		quit(OK)
	else:
		for failure in _failures:
			push_error(failure)
		quit(FAILED)


func _objective_text(hud: Node) -> String:
	var label := hud.get_node_or_null("Root/MissionPanel/Margin/VBox/ObjectiveLabel") as Label
	if label != null:
		return label.text
	label = hud.get_node_or_null("Root/ObjectiveLabel") as Label
	if label != null:
		return label.text
	return ""


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append("FAIL: %s" % message)
