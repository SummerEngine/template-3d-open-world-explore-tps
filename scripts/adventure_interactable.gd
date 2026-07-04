extends Area3D
class_name AdventureInteractable

signal interacted(by: Node)

@export var display_name: String = "Scout"
@export var prompt_action: String = "Talk"
@export var prompt_text: String = ""


func _ready() -> void:
	add_to_group(&"adventure_interactable")
	collision_layer = AdventureLayers.INTERACTABLE
	collision_mask = AdventureLayers.PLAYER


func interact(by: Node) -> void:
	var receiver := get_parent()
	if receiver != null and receiver.has_method("on_interacted_by"):
		receiver.call("on_interacted_by", by)
	interacted.emit(by)


func get_prompt_text() -> String:
	if not prompt_text.is_empty():
		return prompt_text
	return "E  %s" % prompt_action
