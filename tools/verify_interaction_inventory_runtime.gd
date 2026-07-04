extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var player: Node = scene.get_node("Player")
	var hud: Node = scene.get_node("HUD")
	var inventory: Node = scene.get_node("Inventory")
	var input_reader: Node = scene.get_node("InputReader")
	var npc_area: Node = scene.get_node("NPCs/ScoutRobotNPC/QuestGiverArea")
	var relic: Node = scene.get_node("Level/Collectibles/Relic")

	_check(hud.has_method("show_interaction_prompt"), "HUD exposes interaction prompt API.")
	_check(hud.has_method("toggle_inventory"), "HUD exposes inventory toggle API.")
	_check(inventory.has_method("get_item_count"), "Inventory exposes item count API.")

	player.call("_on_interact_area_entered", npc_area)
	player.call("_update_interaction_prompt")
	var prompt_label := hud.get_node("Root/InteractionPrompt/PromptLabel") as Label
	var prompt_bubble := hud.get_node("Root/InteractionPrompt") as PanelContainer
	_check(prompt_bubble.visible, "NPC interaction prompt is visible.")
	_check(prompt_label.text == "E  Talk", "NPC prompt says E to talk.")

	player.call("_on_interact_area_exited", npc_area)
	_check(not prompt_bubble.visible, "Interaction prompt clears when leaving NPC.")

	player.call("_on_interact_area_entered", relic)
	player.call("_update_interaction_prompt")
	_check(prompt_bubble.visible, "Relic interaction prompt is visible.")
	_check(prompt_label.text == "E  Pick up", "Relic prompt says E to pick up.")

	npc_area.call("interact", player)
	relic.call("interact", player)
	_check(inventory.call("get_item_count") == 1, "Relic is added to inventory after interaction.")

	hud.call("open_inventory")
	await process_frame
	var overlay := hud.get_node("Root/InventoryOverlay") as Control
	var panel := hud.get_node("Root/InventoryOverlay/InventoryPanel") as PanelContainer
	var grid := hud.get_node("Root/InventoryOverlay/InventoryPanel/Margin/VBox/Scroll/ItemGrid") as GridContainer
	var tooltip := hud.get_node("Root/ItemTooltip") as PanelContainer
	var viewport_size := root.get_visible_rect().size
	var expected_size := Vector2(max(320.0, viewport_size.x * 0.8), max(360.0, viewport_size.y * 0.9))
	var panel_size_delta := panel.size - expected_size

	_check(overlay.visible, "Inventory overlay opens.")
	_check(not prompt_bubble.visible, "Interaction prompt hides while inventory is open.")
	_check(input_reader.get("recapture_on_mouse_button") == false, "Mouse recapture is disabled while inventory is open.")
	_check(panel_size_delta.x >= -2.0 and panel_size_delta.x <= 16.0 and abs(panel_size_delta.y) <= 2.0, "Inventory panel uses the 80 percent by 90 percent responsive size.")
	_check(grid.get_child_count() == 1, "Inventory grid contains one item card.")

	if grid.get_child_count() > 0:
		var card: Node = grid.get_child(0)
		card.emit_signal("mouse_entered")
		_check(tooltip.visible, "Item tooltip appears on hover.")
		card.emit_signal("mouse_exited")
		_check(not tooltip.visible, "Item tooltip hides after hover exits.")

	hud.call("close_inventory")
	_check(not overlay.visible, "Inventory overlay closes.")
	_check(input_reader.get("recapture_on_mouse_button") == true, "Mouse recapture is restored when inventory closes.")

	if _failures.is_empty():
		print("Interaction inventory runtime verification passed.")
		quit(OK)
	else:
		for failure in _failures:
			push_error(failure)
		quit(FAILED)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append("FAIL: %s" % message)
