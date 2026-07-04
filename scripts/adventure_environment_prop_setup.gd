class_name AdventureEnvironmentPropSetup
extends Node3D

@export_enum("none", "farmhouse", "shed") var material_profile := "none"
@export var apply_procedural_materials := true
@export var generate_mesh_collision := true
@export var visual_root_path: NodePath = ^"."
@export var collision_root_name := "MeshColliders"

var _material_cache := {}


func _ready() -> void:
	call_deferred("apply_setup")


func apply_setup() -> void:
	var visual_root := get_node_or_null(visual_root_path)
	if visual_root == null:
		visual_root = self

	if apply_procedural_materials and material_profile != "none":
		_apply_materials(visual_root)
	if generate_mesh_collision:
		_rebuild_mesh_colliders(visual_root)


func _apply_materials(root_node: Node) -> void:
	for mesh_instance in _collect_mesh_instances(root_node):
		var surface_count := mesh_instance.mesh.get_surface_count()
		for surface in range(surface_count):
			mesh_instance.set_surface_override_material(surface, _material_for_surface(mesh_instance, surface))


func _rebuild_mesh_colliders(root_node: Node) -> void:
	var old := get_node_or_null(collision_root_name)
	if old != null:
		remove_child(old)
		old.free()

	var body := StaticBody3D.new()
	body.name = collision_root_name
	body.collision_layer = AdventureLayers.WORLD
	body.collision_mask = 0
	add_child(body)

	for mesh_instance in _collect_mesh_instances(root_node):
		var shape := mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var collision := CollisionShape3D.new()
		collision.name = "Collision_%s" % mesh_instance.name
		collision.shape = shape
		body.add_child(collision)
		collision.global_transform = mesh_instance.global_transform


func _collect_mesh_instances(root_node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == collision_root_name:
			continue
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh != null:
				meshes.append(mesh_instance)
		for child in node.get_children():
			stack.append(child)
	return meshes


func _material_for_surface(mesh_instance: MeshInstance3D, surface: int) -> Material:
	var source_name := _source_material_name(mesh_instance, surface)
	var key := _material_key(source_name, mesh_instance.name)
	if _material_cache.has(key):
		return _material_cache[key] as Material

	var material: StandardMaterial3D
	match key:
		"farmhouse_roof":
			material = _make_textured_material(key, Color(0.18, 0.155, 0.12), 241, 0.0, 0.96)
		"farmhouse_wood":
			material = _make_textured_material(key, Color(0.34, 0.23, 0.145), 367, 0.0, 0.94)
		"farmhouse_wall":
			material = _make_textured_material(key, Color(0.54, 0.46, 0.34), 491, 0.0, 0.98)
		"shed_rusted_metal":
			material = _make_textured_material(key, Color(0.42, 0.25, 0.16), 619, 0.18, 0.78)
		_:
			material = _make_textured_material(key, Color(0.42, 0.38, 0.31), 733, 0.0, 0.92)

	_material_cache[key] = material
	return material


func _source_material_name(mesh_instance: MeshInstance3D, surface: int) -> String:
	var material := mesh_instance.get_active_material(surface)
	if material == null:
		return ""
	return "%s %s %s" % [material.resource_name, material.resource_path, mesh_instance.name]


func _material_key(source_name: String, mesh_name: StringName) -> String:
	var combined := ("%s %s" % [source_name, String(mesh_name)]).to_lower()
	if material_profile == "shed":
		return "shed_rusted_metal"
	if material_profile == "farmhouse":
		if combined.contains("101"):
			return "farmhouse_roof"
		if combined.contains("81"):
			return "farmhouse_wood"
		if combined.contains("71"):
			return "farmhouse_wall"
		var bucket: int = abs(int(hash(combined))) % 3
		if bucket == 0:
			return "farmhouse_roof"
		if bucket == 1:
			return "farmhouse_wood"
		return "farmhouse_wall"
	return "environment_prop_default"


func _make_textured_material(resource_name: String, albedo: Color, seed: int, metallic: float, roughness: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.105
	noise.fractal_octaves = 4

	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise

	var material := StandardMaterial3D.new()
	material.resource_name = resource_name
	material.albedo_color = albedo
	material.albedo_texture = texture
	material.metallic = metallic
	material.roughness = roughness
	material.uv1_scale = Vector3(2.5, 2.5, 1.0)
	return material
