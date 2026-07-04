extends Node
class_name AdventureQuestState

enum QuestStep { TALK_TO_SCOUT, FIND_RELIC, RETURN_TO_SCOUT, COMPLETE }

@export var hud_path: NodePath
@export var npc_interactable_path: NodePath
@export var collectible_path: NodePath
@export var inventory_path: NodePath
@export var required_item_id: StringName = &"forest_relic"

@onready var hud: Node = get_node_or_null(hud_path)
@onready var npc_interactable: Node = get_node_or_null(npc_interactable_path)
@onready var collectible: Node = get_node_or_null(collectible_path)
@onready var inventory: Node = get_node_or_null(inventory_path)

var step: QuestStep = QuestStep.TALK_TO_SCOUT


func _ready() -> void:
	if npc_interactable != null and npc_interactable.has_signal("interacted"):
		npc_interactable.connect("interacted", Callable(self, "_on_npc_interacted"))
	if collectible != null and collectible.has_signal("collected"):
		collectible.connect("collected", Callable(self, "_on_collectible_collected"))
	_set_objective("Talk to the scout.")


func _on_npc_interacted(_by: Node) -> void:
	match step:
		QuestStep.TALK_TO_SCOUT:
			if _has_required_item():
				step = QuestStep.COMPLETE
				_set_objective("Objective complete.")
				_set_prompt("You already found the relic. Objective complete.")
			else:
				step = QuestStep.FIND_RELIC
				_set_objective("Find the forest relic.")
		QuestStep.RETURN_TO_SCOUT:
			step = QuestStep.COMPLETE
			_set_objective("Objective complete.")
		QuestStep.FIND_RELIC:
			if _has_required_item():
				step = QuestStep.COMPLETE
				_set_objective("Objective complete.")
				_set_prompt("You already found the relic. Objective complete.")
			else:
				_set_prompt("The scout needs the relic first.")
		QuestStep.COMPLETE:
			_set_prompt("The valley is safe for now.")


func _on_collectible_collected(collectible_id: StringName, display_name: String, description: String) -> void:
	if inventory != null and inventory.has_method("add_item"):
		inventory.call("add_item", collectible_id, display_name, description)
	if collectible_id == required_item_id and step == QuestStep.FIND_RELIC:
		step = QuestStep.RETURN_TO_SCOUT
		_set_objective("Return to the scout.")


func _has_required_item() -> bool:
	if inventory != null and inventory.has_method("has_item") and bool(inventory.call("has_item", required_item_id)):
		return true
	if collectible != null and StringName(collectible.get("collectible_id")) == required_item_id and bool(collectible.get("collected_once")):
		return true
	return false


func _set_objective(text: String) -> void:
	if hud != null and hud.has_method("set_objective"):
		hud.call("set_objective", text)


func _set_prompt(text: String) -> void:
	if hud != null and hud.has_method("show_prompt"):
		hud.call("show_prompt", text, 2.0)
