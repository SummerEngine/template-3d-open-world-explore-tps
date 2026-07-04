extends Node3D
class_name AdventureTerrainGrid

@export var target_path: NodePath = ^"../../Player"
@export var terrain_generator_script_path: String = "res://scripts/adventure_terrain_generator.gd"
@export var chunk_size: float = 72.0
@export_range(0, 3, 1) var active_radius: int = 1
@export_range(8, 192, 1) var subdivisions: int = 48
@export var height_scale: float = 2.2
@export var noise_seed: int = 1337
@export var noise_frequency: float = 0.018
@export var ridge_strength: float = 0.35
@export var valley_width: float = 12.0
@export var snap_group_name: StringName = &"snap_to_adventure_terrain"
@export var terrain_material: Material
@export var feature_root_path: NodePath = ^"Features"

@onready var target: Node3D = get_node_or_null(target_path) as Node3D
@onready var feature_root: Node = get_node_or_null(feature_root_path)

var _chunks: Dictionary = {}
var _center_coord := Vector2i(999999, 999999)


func _ready() -> void:
	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node3D
	_update_chunks(true)


func _physics_process(_delta: float) -> void:
	_update_chunks(false)


func get_height_at(global_x: float, global_z: float) -> float:
	return get_height_at_global(global_x, global_z)


func get_height_at_global(global_x: float, global_z: float) -> float:
	var coord := _coord_for_xz(global_x, global_z)
	var chunk := _ensure_chunk(coord)
	if chunk == null:
		return 0.0
	var local := chunk.to_local(Vector3(global_x, 0.0, global_z))
	return chunk.call("get_height_at", local.x, local.z)


func snap_node_to_terrain(node: Node3D, y_offset: float = 0.05) -> void:
	var pos := node.global_position
	pos.y = get_height_at_global(pos.x, pos.z) + y_offset
	node.global_position = pos
	node.reset_physics_interpolation()


func get_active_chunk_count() -> int:
	return _chunks.size()


func get_active_chunk_coords() -> Array:
	var coords: Array = _chunks.keys()
	coords.sort()
	return coords


func refresh_terrain_features() -> void:
	var features := _collect_feature_data()
	for chunk in _chunks.values():
		var terrain_chunk := chunk as Node
		if terrain_chunk == null:
			continue
		terrain_chunk.set("terrain_features", features)
		if terrain_chunk.has_method("generate"):
			terrain_chunk.call("generate")
	_refresh_feature_previews()
	_snap_group_members()


func _update_chunks(force: bool) -> void:
	if target == null:
		return

	var next_center := _coord_for_xz(target.global_position.x, target.global_position.z)
	if not force and next_center == _center_coord:
		return

	_center_coord = next_center
	var wanted := {}
	for z in range(_center_coord.y - active_radius, _center_coord.y + active_radius + 1):
		for x in range(_center_coord.x - active_radius, _center_coord.x + active_radius + 1):
			var coord := Vector2i(x, z)
			wanted[coord] = true
			_ensure_chunk(coord)

	for coord in _chunks.keys():
		if not wanted.has(coord):
			var old_chunk := _chunks[coord] as Node
			_chunks.erase(coord)
			if old_chunk != null:
				old_chunk.queue_free()

	_snap_group_members()


func _ensure_chunk(coord: Vector2i) -> Node3D:
	if _chunks.has(coord):
		return _chunks[coord] as Node3D

	var generator_script := load(terrain_generator_script_path) as Script
	if generator_script == null:
		push_error("AdventureTerrainGrid cannot load terrain generator script: %s" % terrain_generator_script_path)
		return null

	var chunk := generator_script.new() as Node3D
	if chunk == null:
		push_error("AdventureTerrainGrid generator script did not create a Node3D.")
		return null

	chunk.name = "TerrainChunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector3(float(coord.x) * chunk_size, 0.0, float(coord.y) * chunk_size)
	chunk.set("generate_on_ready", false)
	chunk.set("terrain_size", chunk_size)
	chunk.set("subdivisions", subdivisions)
	chunk.set("height_scale", height_scale)
	chunk.set("noise_seed", noise_seed)
	chunk.set("noise_frequency", noise_frequency)
	chunk.set("ridge_strength", ridge_strength)
	chunk.set("valley_width", valley_width)
	chunk.set("sample_origin", Vector2(chunk.position.x, chunk.position.z))
	chunk.set("use_bounded_edge_lift", false)
	chunk.set("use_spawn_clearings", true)
	chunk.set("generate_collision", true)
	chunk.set("snap_group_name", StringName())
	chunk.set("terrain_features", _collect_feature_data())
	if terrain_material != null:
		chunk.set("terrain_material", terrain_material)

	add_child(chunk)
	_chunks[coord] = chunk
	chunk.call("generate")
	return chunk


func _collect_feature_data() -> Array[Dictionary]:
	var features: Array[Dictionary] = []
	if feature_root == null:
		return features
	for child in feature_root.get_children():
		if not child.has_method("get_terrain_feature_data"):
			continue
		var data: Variant = child.call("get_terrain_feature_data")
		if data is Dictionary:
			features.append(data as Dictionary)
	return features


func _refresh_feature_previews() -> void:
	if feature_root == null:
		return
	for child in feature_root.get_children():
		if child.has_method("_rebuild_preview"):
			child.call("_rebuild_preview")


func _coord_for_xz(global_x: float, global_z: float) -> Vector2i:
	return Vector2i(
		floori((global_x / chunk_size) + 0.5),
		floori((global_z / chunk_size) + 0.5)
	)


func _snap_group_members() -> void:
	if snap_group_name == StringName():
		return
	for node in get_tree().get_nodes_in_group(snap_group_name):
		if node is Node3D:
			var offset := 0.45 if node is CharacterBody3D else 0.05
			snap_node_to_terrain(node as Node3D, offset)
			if node is CharacterBody3D:
				(node as CharacterBody3D).velocity = Vector3.ZERO
