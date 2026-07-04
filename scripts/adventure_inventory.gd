extends Node
class_name AdventureInventory

signal item_added(item_id: StringName, display_name: String, description: String)
signal inventory_changed

var _items: Array[Dictionary] = []


func add_item(item_id: StringName, display_name: String, description: String = "") -> void:
	if has_item(item_id):
		return

	var item := {
		"id": item_id,
		"display_name": display_name,
		"description": description,
	}
	_items.append(item)
	item_added.emit(item_id, display_name, description)
	inventory_changed.emit()


func has_item(item_id: StringName) -> bool:
	for item in _items:
		if item.get("id", StringName()) == item_id:
			return true
	return false


func get_items() -> Array[Dictionary]:
	return _items.duplicate(true)


func get_item_count() -> int:
	return _items.size()
