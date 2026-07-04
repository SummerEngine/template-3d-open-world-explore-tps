extends Area3D
class_name AdventureCollectible

signal collected(collectible_id: StringName, display_name: String, description: String)

@export var collectible_id: StringName = &"forest_relic"
@export var display_name: String = "Forest Relic"
@export_multiline var description: String = "A cool blue relic from the old forest path."
@export var prompt_action: String = "Pick up"
@export var auto_collect_on_touch: bool = false

var collected_once: bool = false


func _ready() -> void:
	add_to_group(&"adventure_interactable")
	collision_layer = AdventureLayers.INTERACTABLE
	collision_mask = AdventureLayers.PLAYER
	body_entered.connect(_on_body_entered)


func interact(_by: Node) -> void:
	_collect()


func get_prompt_text() -> String:
	return "E  %s" % prompt_action


func _on_body_entered(body: Node) -> void:
	if auto_collect_on_touch and body.is_in_group(&"player"):
		_collect()


func _collect() -> void:
	if collected_once:
		return
	collected_once = true
	collected.emit(collectible_id, display_name, description)
	visible = false
	set_deferred(&"monitoring", false)
	set_deferred(&"monitorable", false)
