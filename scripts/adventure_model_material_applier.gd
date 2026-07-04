class_name AdventureModelMaterialApplier
extends Node3D

@export var target_path: NodePath
@export var material: Material


func _ready() -> void:
	apply_material()


func apply_material() -> void:
	if material == null:
		return

	var target := get_node_or_null(target_path) if not target_path.is_empty() else self
	if target == null:
		return

	_apply_to_meshes(target)


func _apply_to_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(surface_index, material)

	for child in node.get_children():
		_apply_to_meshes(child)
